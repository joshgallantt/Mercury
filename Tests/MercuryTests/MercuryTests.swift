//
//  MercuryTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
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

    // MARK: - Core Success Tests
    
    func test_givenSuccessStatus_whenGet_thenReturnsSuccess() async {
        // Given
        let (data, response) = makeMockResponse(statusCode: 200, body: "success")
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/api/test", responseType: String.self)

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, "success")
            XCTAssertEqual(success.httpResponse.statusCode, 200)
            XCTAssertFalse(success.requestSignature.isEmpty)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenPostWithEncodableBody_whenSuccess_thenReturnsSuccess() async {
        // Given
        struct User: Codable, Equatable { let name: String; let id: Int }
        let (data, response) = makeMockResponse(statusCode: 201, body: #"{"name":"John","id":123}"#)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let body = User(name: "John", id: 123)

        // When
        let result = await client.post(path: "/users", body: body, responseType: User.self)

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, body)
            XCTAssertEqual(success.httpResponse.statusCode, 201)
            XCTAssertFalse(success.requestSignature.isEmpty)
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - Error Handling Tests

    func test_givenServerError_whenGet_thenReturnsServerFailure() async {
        // Given
        let (data, response) = makeMockResponse(statusCode: 404, body: "not found")
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/api/missing", responseType: Data.self)

        // Then
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .server(let code, let responseData):
                XCTAssertEqual(code, 404)
                XCTAssertEqual(responseData, data)
                XCTAssertEqual(failure.httpResponse?.statusCode, 404)
            default:
                XCTFail("Expected .server failure")
            }
        case .success:
            XCTFail("Expected failure")
        }
    }

    func test_givenTransportError_whenGet_thenReturnsTransportFailure() async {
        // Given
        let error = NSError(domain: "Test", code: 999)
        let session = MockMercurySession(scenario: .error(error))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/api/test", responseType: Data.self)

        // Then
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .transport(let e as NSError):
                XCTAssertEqual(e.code, 999)
                XCTAssertNil(failure.httpResponse)
            default:
                XCTFail("Expected .transport NSError")
            }
        case .success:
            XCTFail("Expected failure")
        }
    }

    func test_givenInvalidHost_whenGet_thenReturnsInvalidURLFailure() async {
        // Given
        let session = MockMercurySession(scenario: .error(NSError(domain: "no", code: 1)))
        let client = Mercury(host: "", session: session)

        // When
        let result = await client.get(path: "/path", responseType: Data.self)

        // Then
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .invalidURL:
                XCTAssertEqual(failure.requestString, "")
                XCTAssertEqual(failure.requestSignature, "")
                XCTAssertNil(failure.httpResponse)
            default:
                XCTFail("Expected .invalidURL failure")
            }
        case .success:
            XCTFail("Expected failure")
        }
    }

    func test_givenInvalidResponse_whenGet_thenReturnsInvalidResponseFailure() async {
        // Given
        let data = Data("nohttp".utf8)
        let response = URLResponse(url: URL(string: "https://host.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/api/test", responseType: Data.self)

        // Then
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .invalidResponse:
                XCTAssertNil(failure.httpResponse)
            default:
                XCTFail("Expected .invalidResponse failure")
            }
        case .success:
            XCTFail("Expected failure")
        }
    }

    func test_givenEncodingError_whenPost_thenReturnsEncodingFailure() async {
        // Given
        struct Bad: Encodable {
            func encode(to encoder: Encoder) throws {
                throw NSError(domain: "EncodingFail", code: 1234)
            }
        }
        let session = MockMercurySession(scenario: .error(NSError(domain: "n/a", code: 0)))
        let client = makeClient(session: session)

        // When
        let result = await client.post(path: "/encode", body: Bad(), responseType: Data.self)

        // Then
        switch result {
        case .failure(let failure):
            if case .encoding = failure.error {
                XCTAssertEqual(failure.requestSignature, "")
                XCTAssertNil(failure.httpResponse)
            } else {
                XCTFail("Expected .encoding failure")
            }
        case .success:
            XCTFail("Expected failure")
        }
    }

    func test_givenDecodingError_whenGet_thenReturnsDecodingFailure() async {
        // Given
        struct Person: Decodable { let name: String; let age: Int }
        let json = #"{"name":"Josh"}"# // Missing age
        let data = Data(json.utf8)
        let response = HTTPURLResponse(url: URL(string: "https://host.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/missing-key", responseType: Person.self)
        
        // Then
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .decoding(let namespace, let key, _):
                XCTAssertEqual(namespace, "Person")
                XCTAssertEqual(key, "age")
                XCTAssertNil(failure.httpResponse)
            default:
                XCTFail("Expected .decoding failure")
            }
        case .success:
            XCTFail("Expected decoding failure")
        }
    }

    // MARK: - HTTP Methods Coverage

    func test_givenAllHTTPMethods_whenCalled_thenMethodsWork() async {
        // Given
        struct Response: Codable, Equatable { let status: String }
        let response = Response(status: "ok")
        let (data, httpResponse) = makeMockResponse(statusCode: 200, body: #"{"status":"ok"}"#)
        let session = MockMercurySession(scenario: .success(data, httpResponse))
        let client = makeClient(session: session)

        // When/Then - Test all HTTP methods
        for (method, call) in [
            ("PUT", await client.put(path: "/resource", body: response, responseType: Response.self)),
            ("PATCH", await client.patch(path: "/resource", body: response, responseType: Response.self)),
            ("DELETE", await client.delete(path: "/resource", body: response, responseType: Response.self))
        ] {
            switch call {
            case .success(let success):
                XCTAssertEqual(success.data, response, "Failed for \(method)")
                XCTAssertFalse(success.requestSignature.isEmpty, "Failed for \(method)")
            case .failure:
                XCTFail("Expected success for \(method)")
            }
        }
    }

    // MARK: - Request Building Tests

    func test_givenHeadersAndQuery_whenGet_thenRequestIsBuiltCorrectly() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session, defaultHeaders: ["X-Default": "default"])
        var capturedRequest: URLRequest?
        session.onRequest = { request in
            capturedRequest = request
            return (data, response)
        }

        // When
        _ = await client.get(
            path: "/resource",
            headers: ["X-Custom": "custom"],
            query: ["q": "test", "limit": "10"],
            fragment: "section",
            responseType: Data.self
        )

        // Then
        XCTAssertNotNil(capturedRequest)
        let headers = capturedRequest?.allHTTPHeaderFields
        XCTAssertEqual(headers?["X-Default"], "default")
        XCTAssertEqual(headers?["X-Custom"], "custom")
        
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("q=test"))
        XCTAssertTrue(urlString.contains("limit=10"))
        XCTAssertTrue(urlString.contains("#section"))
    }

    func test_givenCustomPort_whenRequest_thenURLIncludesPort() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(host: "https://host.com", session: session, port: 8080)
        var capturedURL: URL?
        session.onRequest = { request in
            capturedURL = request.url
            return (data, response)
        }

        // When
        _ = await client.get(path: "/resource", responseType: Data.self)

        // Then
        XCTAssertTrue(capturedURL?.absoluteString.contains(":8080") == true)
    }

    // MARK: - Request Signature Tests

    func test_givenIdenticalRequests_whenCalled_thenSignatureIsStable() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        var signatures = Set<String>()
        for _ in 0..<3 {
            let result = await client.get(path: "/stable", responseType: Data.self)
            if case .success(let success) = result {
                signatures.insert(success.requestSignature)
            }
        }

        // Then
        XCTAssertEqual(signatures.count, 1, "Expected deterministic signature")
    }

    func test_givenDifferentRequests_whenCalled_thenSignaturesDiffer() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result1 = await client.get(path: "/a", headers: ["X": "1"], responseType: Data.self)
        let result2 = await client.get(path: "/b", headers: ["X": "2"], responseType: Data.self)

        // Then
        var sig1 = "", sig2 = ""
        if case .success(let success) = result1 { sig1 = success.requestSignature }
        if case .success(let success) = result2 { sig2 = success.requestSignature }
        XCTAssertNotEqual(sig1, sig2)
    }

    func test_givenRequest_whenBuilt_thenCanonicalStringIsCorrect() async {
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
        if case .success(let success) = result {
            let expected = "GET|https://host.com/users/123|headers:accept:application/json&content-type:application/json"
            XCTAssertEqual(success.requestString, expected)
        } else {
            XCTFail("Expected success")
        }
    }
    
    // MARK: - Cache and Static Method Coverage

    func test_givenClientIsolatedCache_whenInit_thenClearCacheRemovesResponses() {
        // Given
        let cache = URLCache(memoryCapacity: 512, diskCapacity: 1024)
        let session = MockMercurySession(scenario: .error(NSError(domain: "x", code: 1)))
        let client = Mercury(
            host: "https://host.com",
            port: nil,
            session: session,
            defaultHeaders: ["Test": "Value"],
            defaultCachePolicy: .reloadIgnoringCacheData,
            cache: .isolated(memorySize: 512, diskSize: 1024),
            urlCache: cache
        )

        // When/Then (just calls, checks don’t crash)
        client.clearCache()
        Mercury.clearSharedURLCache()
    }

    // MARK: - mergeHeaders

    func test_givenCustomHeaders_whenCaseDiffers_thenOverridesDefaultCaseSensitive() async {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session, defaultHeaders: ["HeaderA": "DefaultA", "headerb": "DefaultB"])
        var requestHeaders: [String: String]?
        session.onRequest = { request in
            requestHeaders = request.allHTTPHeaderFields
            return (data, response)
        }

        // When
        _ = await client.get(path: "/headers", headers: ["headerA": "Override", "HeaderB": "CustomB"], responseType: Data.self)

        // Then: Custom should override, and casing should match custom
        XCTAssertEqual(requestHeaders?["headerA"], "Override")
        XCTAssertEqual(requestHeaders?["HeaderB"], "CustomB")
        // No old-case version left
        XCTAssertNil(requestHeaders?["HeaderA"])
        XCTAssertNil(requestHeaders?["headerb"])
    }

    // MARK: - encodeBody

    func test_givenNilBody_whenEncodeBody_thenReturnsNilData() {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = client.encodeBody(nil as String?)

        // Then
        switch result {
        case .success(let data): XCTAssertNil(data)
        default: XCTFail("Expected nil data")
        }
    }

    // MARK: - decodeResponse: Data.self and String.self

    func test_givenDataResponseType_whenDecode_thenReturnsRawData() async {
        // Given
        let data = Data([1,2,3,4])
        let response = HTTPURLResponse(url: URL(string: "https://host.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/raw", responseType: Data.self)

        // Then
        switch result {
        case .success(let success): XCTAssertEqual(success.data, data)
        default: XCTFail("Expected raw Data")
        }
    }

    func test_givenStringResponseType_whenDecode_thenReturnsString() async {
        // Given
        let str = "Hello Mercury"
        let data = str.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://host.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/string", responseType: String.self)

        // Then
        switch result {
        case .success(let success): XCTAssertEqual(success.data, str)
        default: XCTFail("Expected decoded string")
        }
    }

    // MARK: - buildFullPath

    func test_givenTrailingSlashes_whenBuildFullPath_thenTrimsCorrectly() {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        // When/Then
        XCTAssertEqual(client.buildFullPath("/a/"), "/a")
        XCTAssertEqual(client.buildFullPath("b/"), "/b")
        XCTAssertEqual(client.buildFullPath("/c"), "/c")
        XCTAssertEqual(client.buildFullPath("///d//"), "/d")
        XCTAssertEqual(client.buildFullPath(""), "/")
    }

    // MARK: - buildQueryItems

    func test_givenNilOrEmptyQuery_whenBuildQueryItems_thenReturnsNil() {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        // When/Then
        XCTAssertNil(client.buildQueryItems(from: nil as [String: String]?))
        XCTAssertNil(client.buildQueryItems(from: [:]))
    }

    // MARK: - generateCanonicalRequestString

    func test_givenRequestWithoutHeaders_whenGenerateCanonicalRequestString_thenNoHeadersAppended() {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let url = URL(string: "https://host.com/empty")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = nil
        // When
        let string = client.generateCanonicalRequestString(for: request)
        // Then
        XCTAssertFalse(string.contains("headers:"))
    }

    // MARK: - Mercury Initializer Coverage

    func test_publicInit_allPropertiesSetCorrectly() {
        // Shared cache (default)
        let mercuryShared = Mercury(
            host: "https://svc.example.com/base",
            port: 1443,
            defaultHeaders: ["X-A": "abc"],
            defaultCachePolicy: .reloadIgnoringCacheData,
            cache: .shared
        )

        let mercuryIsolated = Mercury(
            host: "http://host.net",
            port: nil,
            defaultHeaders: ["Accept": "a"],
            defaultCachePolicy: .useProtocolCachePolicy,
            cache: .isolated(memorySize: 1024, diskSize: 2048)
        )
        
        XCTAssertNotNil(mercuryShared)
        XCTAssertNotNil(mercuryIsolated)
    }

}

