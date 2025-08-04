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
            case .decodingFailed(let namespace, let key, let underlying):
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
            case .decodingFailed(_, let key, let underlying):
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
            case .decodingFailed(_, let key, let underlying):
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
            case .decodingFailed(_, let key, let underlying):
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
    
}

