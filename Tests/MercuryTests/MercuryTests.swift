//
//  MercuryTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


//
//  MercuryTests.swift
//  MercuryTests
//
//  Created by Josh Gallant on 14/07/2025.
//

import XCTest
@testable import Mercury

final class MercuryTests: XCTestCase {
    
    // MARK: - Helpers

    func makeClient(
        host: String = "https://host.com",
        session: MercurySession,
        port: Int? = nil,
        defaultHeaders: [String: String]? = nil
    ) -> Mercury {
        Mercury(
            host: host,
            port: port,
            session: session,
            defaultHeaders: defaultHeaders ?? [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
        )
    }
    
    func makeClientWithPublicInit(
        host: String = "https://host.com",
        port: Int? = nil,
        defaultHeaders: [String: String]? = nil
    ) -> Mercury {
        Mercury(
            host: host,
            port: port,
            defaultHeaders: defaultHeaders ?? [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
        )
    }

    func makeMockResponse(
        statusCode: Int = 200,
        body: String = "ok"
    ) -> (Data, HTTPURLResponse) {
        let data = body.data(using: .utf8) ?? Data()
        let url = URL(string: "https://host.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    // MARK: - Tests
    
    func test_ClientInitializes() async {
        let _ = makeClientWithPublicInit(host: "https://host.com:8888")

        XCTAssertTrue(true)
    }

    func test_givenSuccessStatus_whenGet_thenReturnsHTTPSuccess_andIncludesSignature() async {
        let (data, response) = makeMockResponse(statusCode: 200, body: "yay")
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/api/test", responseType: String.self)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, "yay")
            XCTAssertEqual(success.httpResponse.statusCode, 200)
            XCTAssertFalse(success.requestSignature.isEmpty)
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenNonSuccessStatus_whenGet_thenReturnsServerFailure_withSignature() async {
        let (data, response) = makeMockResponse(statusCode: 404, body: "not found")
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/api/test", responseType: Data.self)

        switch result {
        case .failure(let failure):
            switch failure.error {
            case .server(let code, let responseData):
                XCTAssertEqual(code, 404)
                XCTAssertEqual(responseData, data)
                XCTAssertFalse(failure.requestSignature.isEmpty)
            default:
                XCTFail("Expected .server failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }

    func test_givenTransportError_whenGet_thenReturnsTransportFailure_withSignature() async {
        let error = NSError(domain: "Test", code: 999)
        let session = MockMercurySession(scenario: .error(error))
        let client = makeClient(session: session)

        let result = await client.get(path: "/api/test", responseType: Data.self)

        switch result {
        case .failure(let failure):
            switch failure.error {
            case .transport(let e as NSError):
                XCTAssertEqual(e.code, 999)
                XCTAssertFalse(failure.requestSignature.isEmpty)
            default:
                XCTFail("Expected .transport NSError")
            }
        default:
            XCTFail("Expected failure")
        }
    }

    func test_givenInvalidResponse_whenGet_thenReturnsInvalidResponseFailure_withSignature() async {
        let data = Data("nohttp".utf8)
        let response = URLResponse(url: URL(string: "https://host.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/api/test", responseType: Data.self)

        switch result {
        case .failure(let failure):
            switch failure.error {
            case .invalidResponse:
                XCTAssertFalse(failure.requestSignature.isEmpty)
            default:
                XCTFail("Expected .invalidResponse failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }

    func test_givenInvalidHost_whenGet_thenReturnsInvalidURLFailure_withEmptySignature() async {
        let session = MockMercurySession(scenario: .error(NSError(domain: "no", code: 1)))
        let client = Mercury(host: "", session: session)

        let result = await client.get(path: "/path", responseType: Data.self)

        switch result {
        case .failure(let failure):
            switch failure.error {
            case .invalidURL:
                XCTAssertEqual(failure.requestString, "")
                XCTAssertEqual(failure.requestSignature, "")
            default:
                XCTFail("Expected .invalidURL failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }

    func test_givenSameRequestMultipleTimes_thenRequestSignatureIsStable() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        var signatures = Set<String>()
        for _ in 0..<5 {
            let result = await client.get(path: "/stable", responseType: Data.self)
            if case .success(let success) = result {
                signatures.insert(success.requestSignature)
            } else if case .failure(let failure) = result {
                signatures.insert(failure.requestSignature)
            }
        }

        XCTAssertEqual(signatures.count, 1, "Expected deterministic and consistent signature")
    }

    func test_givenHeaders_whenRequest_thenMergedWithDefaultHeaders() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session, defaultHeaders: ["X-Default": "1"])
        var capturedHeaders: [String: String]?
        session.onRequest = { request in
            capturedHeaders = request.allHTTPHeaderFields
            return (data, response)
        }

        _ = await client.get(path: "/path", headers: ["X-Custom": "2"], responseType: Data.self)

        XCTAssertEqual(capturedHeaders?["X-Default"], "1")
        XCTAssertEqual(capturedHeaders?["X-Custom"], "2")
    }

    func test_givenPostWithData_whenSuccess_thenReturnsSuccess_andIncludesSignature() async {
        let (data, response) = makeMockResponse(statusCode: 201)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let body = Data("body".utf8)

        let result = await client.post(path: "/create", body: body, responseType: Data.self)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, data)
            XCTAssertEqual(success.httpResponse.statusCode, 201)
            XCTAssertFalse(success.requestSignature.isEmpty)
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenPutPatchDelete_whenSuccess_thenReturnsSuccess_andIncludesSignature() async {
        let (data, response) = makeMockResponse(statusCode: 204)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let body = Data("x".utf8)

        for call in [
            await client.put(path: "/resource", body: body, responseType: Data.self),
            await client.patch(path: "/resource", body: body, responseType: Data.self),
            await client.delete(path: "/resource", body: body, responseType: Data.self)
        ] {
            switch call {
            case .success(let success):
                XCTAssertEqual(success.value, data)
                XCTAssertEqual(success.httpResponse.statusCode, 204)
                XCTAssertFalse(success.requestSignature.isEmpty)
            default:
                XCTFail("Expected success")
            }
        }
    }

    func test_givenQueryItemsAndFragment_whenGet_thenURLIncludesQueryAndFragment() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        var capturedURL: URL?
        session.onRequest = { request in
            capturedURL = request.url
            return (data, response)
        }

        _ = await client.get(
            path: "/resource",
            query: ["foo": "bar", "x": "y"],
            fragment: "frag",
            responseType: Data.self
        )

        XCTAssertNotNil(capturedURL)
        let urlString = capturedURL!.absoluteString
        let expected1 = "https://host.com/resource?foo=bar&x=y#frag"
        let expected2 = "https://host.com/resource?x=y&foo=bar#frag"
        XCTAssertTrue(urlString == expected1 || urlString == expected2)
    }

    func test_givenCustomPort_whenClientInitializes_thenURLIncludesPort() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(host: "https://host.com:8888", session: session)
        var capturedURL: URL?
        session.onRequest = { request in
            capturedURL = request.url
            return (data, response)
        }

        _ = await client.get(path: "/resource", responseType: Data.self)

        XCTAssertNotNil(capturedURL)
        XCTAssertTrue(capturedURL!.absoluteString.contains(":8888"))
    }

    func test_givenEncodablePost_whenEncodingSucceeds_thenCallsPostWithData_andIncludesSignature() async {
        struct Good: Encodable { let value: String }
        let (data, response) = makeMockResponse(statusCode: 201)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let good = Good(value: "abc")

        let result = await client.post(path: "/encode", body: good, responseType: Data.self)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, data)
            XCTAssertEqual(success.httpResponse.statusCode, 201)
            XCTAssertFalse(success.requestSignature.isEmpty)
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenPostEncodableBody_whenEncodingFails_thenReturnsEncodingFailure_andEmptySignature() async {
        struct Bad: Encodable {
            func encode(to encoder: Encoder) throws {
                throw NSError(domain: "EncodingFail", code: 1234)
            }
        }
        let session = MockMercurySession(scenario: .error(NSError(domain: "n/a", code: 0)))
        let client = makeClient(session: session)
        let result = await client.post(path: "/encode", body: Bad(), responseType: Data.self)
        switch result {
        case .failure(let failure):
            if case .encoding = failure.error {
                XCTAssertEqual(failure.requestSignature, "")
            } else {
                XCTFail("Expected .encoding failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }

    func test_givenEmptyHost_whenGet_thenReturnsInvalidURLFailure_withEmptySignature() async {
        let session = MockMercurySession(scenario: .error(NSError(domain: "test", code: 1)))
        let client = Mercury(host: "", session: session)
        let result = await client.get(path: "/foo", responseType: Data.self)

        switch result {
        case .failure(let failure):
            if case .invalidURL = failure.error {
                XCTAssertEqual(failure.requestSignature, "")
            } else {
                XCTFail("Expected .invalidURL failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_givenInvalidJSON_whenDecodeResponse_thenReturnsDecodingFailed_withKeyPath() async {
        struct Person: Decodable {
            let name: String
            let age: Int
        }
        // "name" is present, "age" is missing => triggers .keyNotFound
        let json = #"{"name":"Josh"}"#
        let data = Data(json.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://host.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/missing-key", responseType: Person.self)
        
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .decoding(let namespace, let key, let underlying):
                XCTAssertEqual(namespace, "Person")
                XCTAssertEqual(key, "age") // The keyPath should be "age" for keyNotFound
                XCTAssertTrue("\(underlying)".contains("keyNotFound"))
            default:
                XCTFail("Expected .decodingFailed")
            }
        default:
            XCTFail("Expected decoding failure")
        }
    }
    
    func test_givenTypeMismatch_whenDecodeResponse_thenKeyPathIsContextPath() async {
        struct Model: Decodable { let id: Int }
        // id should be Int, giving String to trigger typeMismatch
        let json = #"{"id":"notAnInt"}"#
        let data = Data(json.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://host.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/type-mismatch", responseType: Model.self)
        
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .decoding(_, let key, let underlying):
                XCTAssertEqual(key, "id")
                XCTAssertTrue("\(underlying)".contains("typeMismatch"))
            default:
                XCTFail("Expected .decodingFailed with typeMismatch")
            }
        default:
            XCTFail("Expected decoding failure")
        }
    }
    
    func test_givenValueNotFound_whenDecodeResponse_thenKeyPathIsContextPath() async {
        struct Model: Decodable { let id: Int? }
        // valueNotFound is tricky, but decoding `nil` for non-optional will trigger valueNotFound
        struct NonOptional: Decodable { let id: Int }
        let json = #"{"id":null}"#
        let data = Data(json.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://host.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/value-not-found", responseType: NonOptional.self)

        switch result {
        case .failure(let failure):
            switch failure.error {
            case .decoding(_, let key, let underlying):
                XCTAssertEqual(key, "id")
                XCTAssertTrue("\(underlying)".contains("valueNotFound"))
            default:
                XCTFail("Expected .decodingFailed with valueNotFound")
            }
        default:
            XCTFail("Expected decoding failure")
        }
    }
    
    func test_givenDataCorrupted_whenDecodeResponse_thenKeyPathIsContextPath() async {
        struct Model: Decodable { let id: Date }
        let json = #"{"id":"invalid-date"}"#
        let data = Data(json.utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://host.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/data-corrupted", responseType: Model.self)
        
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .decoding(_, let key, let underlying):
                XCTAssertEqual(key, "id")
                if let decodingError = underlying as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted, .typeMismatch:
                        break // Success!
                    default:
                        XCTFail("Expected underlying to be .dataCorrupted or .typeMismatch")
                    }
                } else {
                    XCTFail("Underlying error not DecodingError")
                }
            default:
                XCTFail("Expected .decodingFailed")
            }
        default:
            XCTFail("Expected decoding failure")
        }
    }
    
    func test_givenNestedEncodable_whenPost_thenEncodesSuccessfully_andIncludesSignature() async {
        struct Inner: Encodable { let id: Int }
        struct Outer: Encodable { let name: String; let inner: Inner }

        let payload = Outer(name: "Josh", inner: Inner(id: 99))
        let (mockData, mockResponse) = makeMockResponse(statusCode: 200)
        let session = MockMercurySession(scenario: .success(mockData, mockResponse))
        let client = makeClient(session: session)

        var capturedBody: Data?
        session.onRequest = { request in
            capturedBody = request.httpBody
            return (mockData, mockResponse)
        }

        let result = await client.post(path: "/nested", body: payload, responseType: Data.self)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, mockData)
            XCTAssertFalse(success.requestSignature.isEmpty)

            guard let body = capturedBody else {
                return XCTFail("Expected captured HTTP body")
            }

            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["name"] as? String, "Josh")
            if let inner = json?["inner"] as? [String: Any] {
                XCTAssertEqual(inner["id"] as? Int, 99)
            } else {
                XCTFail("Missing nested 'inner' object")
            }
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenNestedDecodable_whenGet_thenDecodesSuccessfully_andIncludesSignature() async {
        struct Inner: Decodable, Equatable { let id: Int }
        struct Outer: Decodable, Equatable { let name: String; let inner: Inner }

        let json = #"{"name":"Josh","inner":{"id":42}}"#
        let data = Data(json.utf8)
        let response = HTTPURLResponse(url: URL(string: "https://host.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get(path: "/nested", responseType: Outer.self)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, Outer(name: "Josh", inner: Inner(id: 42)))
            XCTAssertEqual(success.httpResponse.statusCode, 200)
            XCTAssertFalse(success.requestSignature.isEmpty)
        default:
            XCTFail("Expected success")
        }
    }
    
    func test_givenHeadersInDifferentOrder_whenGet_thenSignatureIsIdentical() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result1 = await client.get(
            path: "/sigtest",
            headers: ["X-Auth": "token", "Accept": "application/json"],
            responseType: Data.self
        )
        let result2 = await client.get(
            path: "/sigtest",
            headers: ["Accept": "application/json", "X-Auth": "token"],
            responseType: Data.self
        )

        var sig1 = ""
        switch result1 {
        case .success(let success): sig1 = success.requestSignature
        case .failure(let failure): sig1 = failure.requestSignature
        }
        var sig2 = ""
        switch result2 {
        case .success(let success): sig2 = success.requestSignature
        case .failure(let failure): sig2 = failure.requestSignature
        }

        XCTAssertEqual(sig1, sig2, "Signature should be the same for headers in any order")
    }

    func test_givenIdenticalRequestMultipleTimes_thenSignatureIsStable() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        var signatures = Set<String>()
        for _ in 0..<5 {
            let result = await client.get(path: "/deterministic", responseType: Data.self)
            switch result {
            case .success(let success): signatures.insert(success.requestSignature)
            case .failure(let failure): signatures.insert(failure.requestSignature)
            }
        }
        XCTAssertEqual(signatures.count, 1, "Signature should be stable and deterministic across identical requests")
    }

    func test_givenRequestsWithDifferentHeaders_thenSignatureIsDifferent() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result1 = await client.get(
            path: "/diff",
            headers: ["A": "1"],
            responseType: Data.self
        )
        let result2 = await client.get(
            path: "/diff",
            headers: ["A": "2"],
            responseType: Data.self
        )

        var sig1 = ""
        switch result1 {
        case .success(let success): sig1 = success.requestSignature
        case .failure(let failure): sig1 = failure.requestSignature
        }
        var sig2 = ""
        switch result2 {
        case .success(let success): sig2 = success.requestSignature
        case .failure(let failure): sig2 = failure.requestSignature
        }

        XCTAssertNotEqual(sig1, sig2, "Signature should differ for different headers")
    }

    func test_givenRequestsWithDifferentMethod_thenSignatureIsDifferent() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let getResult = await client.get(path: "/method", responseType: Data.self)
        let postResult = await client.post(path: "/method", body: Data(), responseType: Data.self)

        var getSig = ""
        switch getResult {
        case .success(let success): getSig = success.requestSignature
        case .failure(let failure): getSig = failure.requestSignature
        }
        var postSig = ""
        switch postResult {
        case .success(let success): postSig = success.requestSignature
        case .failure(let failure): postSig = failure.requestSignature
        }

        XCTAssertNotEqual(getSig, postSig, "Signature should differ for GET vs POST")
    }

    func test_givenRequestsWithDifferentURLs_thenSignatureIsDifferent() async {
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result1 = await client.get(path: "/a", responseType: Data.self)
        let result2 = await client.get(path: "/b", responseType: Data.self)

        var sig1 = ""
        switch result1 {
        case .success(let success): sig1 = success.requestSignature
        case .failure(let failure): sig1 = failure.requestSignature
        }
        var sig2 = ""
        switch result2 {
        case .success(let success): sig2 = success.requestSignature
        case .failure(let failure): sig2 = failure.requestSignature
        }

        XCTAssertNotEqual(sig1, sig2, "Signature should differ for different URLs")
    }

    func test_givenSimpleGetRequest_whenGet_thenRequestStringIsCanonical() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        // When
        let result = await client.get(
            path: "/users/123",
            headers: ["Accept": "application/json"],
            responseType: Data.self
        )
        
        // Then
        switch result {
        case .success(let success):
            // Both headers, sorted and lowercased, in canonical string:
            let expected = "GET|https://host.com/users/123|headers:accept:application/json&content-type:application/json"
            XCTAssertEqual(success.requestString, expected)
        default:
            XCTFail("Expected success")
        }
    }
    
    func test_givenCustomHeaderCasing_whenMerged_thenCustomCasingWinsAndNoDuplicates() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let customHeaders = ["content-type": "custom/type", "X-Api-Token": "abc123"]
        var capturedHeaders: [String: String] = [:]
        session.onRequest = { request in
            capturedHeaders = request.allHTTPHeaderFields ?? [:]
            return (data, response)
        }
        
        // When
        let result = await client.get(
            path: "/casing",
            headers: customHeaders,
            responseType: Data.self
        )
        
        // Then
        switch result {
        case .success:
            XCTAssertEqual(capturedHeaders["Content-Type"], "custom/type")
            XCTAssertEqual(capturedHeaders["X-Api-Token"], "abc123")
            XCTAssertEqual(capturedHeaders["Accept"], "application/json")
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenHeadersInDifferentOrder_whenGet_thenRequestStringIsIdentical() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let headers1 = ["X-Foo": "bar", "Accept": "application/json"]
        let headers2 = ["Accept": "application/json", "X-Foo": "bar"]
        
        // When
        let result1 = await client.get(path: "/alpha", headers: headers1, responseType: Data.self)
        let result2 = await client.get(path: "/alpha", headers: headers2, responseType: Data.self)
        
        // Then
        var s1 = "", s2 = ""
        switch result1 {
        case .success(let success): s1 = success.requestString
        default: XCTFail("Expected success")
        }
        switch result2 {
        case .success(let success): s2 = success.requestString
        default: XCTFail("Expected success")
        }
        XCTAssertEqual(s1, s2, "Request string should be identical regardless of header order")
    }

    func test_givenCustomContentType_whenMergedWithDefault_thenCustomOverridesInRequestString() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        // Client defaults: Accept and Content-Type
        let client = makeClient(session: session)

        // Per-request headers override Content-Type only
        let customHeaders = [
            "Content-Type": "custom/type",
            "X-Token": "abc"
        ]

        // When
        let result = await client.post(path: "/thing", body: Data(), headers: customHeaders, responseType: Data.self)

        // Then
        switch result {
        case .success(let success):
            let expected = "POST|https://host.com/thing|headers:accept:application/json&content-type:custom/type&x-token:abc"
            XCTAssertEqual(success.requestString, expected)
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenRequestsWithDifferentHeaders_thenRequestStringIsDifferent() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        let result1 = await client.get(path: "/abc", headers: ["A": "1"], responseType: Data.self)
        let result2 = await client.get(path: "/abc", headers: ["A": "2"], responseType: Data.self)
        
        var s1 = "", s2 = ""
        switch result1 {
        case .success(let success): s1 = success.requestString
        default: XCTFail("Expected success")
        }
        switch result2 {
        case .success(let success): s2 = success.requestString
        default: XCTFail("Expected success")
        }
        XCTAssertNotEqual(s1, s2, "Request string should differ for different header values")
    }

    func test_givenRequestsWithDifferentPaths_thenRequestStringIsDifferent() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        let result1 = await client.get(path: "/foo", responseType: Data.self)
        let result2 = await client.get(path: "/bar", responseType: Data.self)
        
        var s1 = "", s2 = ""
        switch result1 {
        case .success(let success): s1 = success.requestString
        default: XCTFail("Expected success")
        }
        switch result2 {
        case .success(let success): s2 = success.requestString
        default: XCTFail("Expected success")
        }
        XCTAssertNotEqual(s1, s2, "Request string should differ for different URLs")
    }
    
    func test_givenRequestWithFragment_thenRequestStringIncludesFragment() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        // When
        let result = await client.get(
            path: "/resource",
            fragment: "section-2",
            responseType: Data.self
        )
        
        // Then
        switch result {
        case .success(let success):
            XCTAssertTrue(success.requestString.contains("#section-2"), "Request string should contain the fragment")
            XCTAssertTrue(success.requestString.contains("https://host.com/resource#section-2"))
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenRequestsWithAndWithoutFragment_thenSignaturesAreDifferent() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result1 = await client.get(
            path: "/resource",
            responseType: Data.self
        )
        let result2 = await client.get(
            path: "/resource",
            fragment: "frag",
            responseType: Data.self
        )

        // Then
        var sig1 = "", sig2 = ""
        switch result1 {
        case .success(let success): sig1 = success.requestSignature
        default: XCTFail("Expected success")
        }
        switch result2 {
        case .success(let success): sig2 = success.requestSignature
        default: XCTFail("Expected success")
        }
        XCTAssertNotEqual(sig1, sig2, "Signature should differ when fragment changes")
    }

}

