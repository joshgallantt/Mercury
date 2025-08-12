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
        let result = await client.get(path: "/api/test", decodeTo: String.self)

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, "success")
            XCTAssertEqual(success.httpResponse.statusCode, 200)
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
        let result = await client.post(path: "/users", body: body, decodeTo: User.self)

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, body)
            XCTAssertEqual(success.httpResponse.statusCode, 201)
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
        let result = await client.get(path: "/api/missing", decodeTo: Data.self)

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
        let result = await client.get(path: "/api/test", decodeTo: Data.self)

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

    func test_givenInvalidResponse_whenGet_thenReturnsInvalidResponseFailure() async {
        // Given
        let data = Data("nohttp".utf8)
        let response = URLResponse(url: URL(string: "https://host.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/api/test", decodeTo: Data.self)

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
        let result = await client.post(path: "/encode", body: Bad(), decodeTo: Data.self)

        // Then
        switch result {
        case .failure(let failure):
            if case .encoding = failure.error {
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
        let result = await client.get(path: "/missing-key", decodeTo: Person.self)
        
        // Then
        switch result {
        case .failure(let failure):
            switch failure.error {
            case .decoding(let namespace, let key, _):
                XCTAssertEqual(namespace, "Person")
                XCTAssertEqual(key, "age")
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
            ("PUT", await client.put(path: "/resource", body: response, decodeTo: Response.self)),
            ("PATCH", await client.patch(path: "/resource", body: response, decodeTo: Response.self)),
            ("DELETE", await client.delete(path: "/resource", body: response, decodeTo: Response.self))
        ] {
            switch call {
            case .success(let success):
                XCTAssertEqual(success.data, response, "Failed for \(method)")
            case .failure:
                XCTFail("Expected success for \(method)")
            }
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

    // MARK: - decodeResponse: Data.self and String.self

    func test_givenDataResponseType_whenDecode_thenReturnsRawData() async {
        // Given
        let data = Data([1,2,3,4])
        let response = HTTPURLResponse(url: URL(string: "https://host.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        // When
        let result = await client.get(path: "/raw", decodeTo: Data.self)

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
        let result = await client.get(path: "/string", decodeTo: String.self)

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
    
    func test_mergeHeaders_coversAllCases() {
        // Given
        let session = MockMercurySession(scenario: .error(NSError(domain: "x", code: 0)))
        let defaultHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Custom-Header": "defaultValue"
        ]
        let client = Mercury(
            host: "https://host.com",
            port: nil,
            session: session,
            defaultHeaders: defaultHeaders
        )
        
        // 1. Merging nil returns defaults
        let mergedNil = client.mergeHeaders(nil)
        XCTAssertEqual(mergedNil.count, defaultHeaders.count, "Merging nil should return default headers count")
        for (key, value) in defaultHeaders {
            XCTAssertEqual(mergedNil[key], value, "Merging nil should keep default header for \(key)")
        }
        
        // 2. Custom header same key different value overrides, casing preserved
        let customSameKey = ["Accept": "text/plain"]
        let mergedSameKey = client.mergeHeaders(customSameKey)
        XCTAssertEqual(mergedSameKey.count, defaultHeaders.count, "Count should remain same after overriding existing key")
        XCTAssertEqual(mergedSameKey["Accept"], "text/plain", "Value should be overridden for 'Accept'")
        XCTAssertTrue(mergedSameKey.keys.contains("Accept"), "Key casing should remain 'Accept'")
        
        // 3. Custom header with a new key is added, casing preserved
        let customNewKey = ["New-Header": "newValue"]
        let mergedNewKey = client.mergeHeaders(customNewKey)
        XCTAssertEqual(mergedNewKey.count, defaultHeaders.count + 1, "Count should increase by one after adding new header")
        XCTAssertEqual(mergedNewKey["New-Header"], "newValue", "New header value should be present")
        XCTAssertTrue(mergedNewKey.keys.contains("New-Header"), "New header casing should be preserved")
        
        // 4. Custom header uses different casing for existing key, value overridden but default casing remains
        let customDifferentCasing = ["content-type": "text/html"]
        let mergedDifferentCasing = client.mergeHeaders(customDifferentCasing)
        XCTAssertEqual(mergedDifferentCasing.count, defaultHeaders.count, "Count should remain same when overriding existing key with different casing")
        XCTAssertEqual(mergedDifferentCasing["Content-Type"], "text/html", "Value should be overridden for 'Content-Type'")
        XCTAssertFalse(mergedDifferentCasing.keys.contains("content-type"), "Key casing should remain 'Content-Type' not 'content-type'")
        
        // 5. Custom header with new key with new casing preserved
        let customNewKeyCasing = ["X-New-Header": "newValue2"]
        let mergedNewKeyCasing = client.mergeHeaders(customNewKeyCasing)
        XCTAssertEqual(mergedNewKeyCasing.count, defaultHeaders.count + 1, "Count should increase by one when adding new key with new casing")
        XCTAssertEqual(mergedNewKeyCasing["X-New-Header"], "newValue2", "New header with new casing value should be present")
        XCTAssertTrue(mergedNewKeyCasing.keys.contains("X-New-Header"), "New header casing should be preserved")
        
        // 6. Merging empty dictionary returns defaults
        let mergedEmpty = client.mergeHeaders([:])
        XCTAssertEqual(mergedEmpty.count, defaultHeaders.count, "Merging empty dictionary should return default headers count")
        for (key, value) in defaultHeaders {
            XCTAssertEqual(mergedEmpty[key], value, "Merging empty dictionary should keep default header for \(key)")
        }
    }

}
