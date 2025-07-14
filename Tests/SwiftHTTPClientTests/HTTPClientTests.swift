//
//  HTTPClientTests 2.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 14/07/2025.
//


import XCTest
@testable import SwiftHTTPClient

final class HTTPClientTests: XCTestCase {
    
    // MARK: - Helper
    
    func makeClient(
        host: String = "https://host.com",
        session: HTTPSession,
        port: Int? = nil,
        defaultHeaders: [String: String]? = nil
    ) -> SwiftHTTPClient {
        SwiftHTTPClient(
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
    
    // MARK: - Tests
    
    func test_givenSuccessStatus_whenGet_thenReturnsHTTPSuccess() async throws {
        // Given
        let (data, response) = makeMockResponse(statusCode: 200, body: "yay")
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        // When
        let result = await client.get("/api/test")
        
        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, data)
            XCTAssertEqual(success.response.statusCode, 200)
        case .failure:
            XCTFail("Expected success")
        }
    }
    
    func test_givenNonSuccessStatus_whenGet_thenReturnsServerFailure() async throws {
        // Given
        let (data, response) = makeMockResponse(statusCode: 404, body: "not found")
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        // When
        let result = await client.get("/api/test")
        
        // Then
        switch result {
        case .failure(let failure):
            if case let .server(status, errData) = failure {
                XCTAssertEqual(status, 404)
                XCTAssertEqual(errData, data)
            } else {
                XCTFail("Expected .server failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_givenTransportError_whenGet_thenReturnsTransportFailure() async throws {
        // Given
        let error = NSError(domain: "Test", code: 999)
        let session = MockHTTPSession(scenario: .error(error))
        let client = makeClient(session: session)
        
        // When
        let result = await client.get("/api/test")
        
        // Then
        switch result {
        case .failure(let failure):
            if case let .transport(err) = failure {
                XCTAssertEqual((err as NSError).code, 999)
            } else {
                XCTFail("Expected .transport failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_givenInvalidResponse_whenGet_thenReturnsInvalidResponseFailure() async throws {
        // Given
        let data = Data("nohttp".utf8)
        let response = URLResponse(url: URL(string: "https://host.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        
        // When
        let result = await client.get("/api/test")
        
        // Then
        switch result {
        case .failure(let failure):
            if case .invalidResponse = failure {
                // pass
            } else {
                XCTFail("Expected .invalidResponse")
            }
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_givenInvalidHost_whenGet_thenReturnsInvalidURLFailure() async throws {
        // Given
        let session = MockHTTPSession(scenario: .error(NSError(domain: "no", code: 1)))
        let client = SwiftHTTPClient(host: "", session: session)
        
        // When
        let result = await client.get("/path")
        
        // Then
        switch result {
        case .failure(let failure):
            if case .invalidURL = failure {
                // pass
            } else {
                XCTFail("Expected .invalidURL")
            }
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_givenPostEncodableBody_whenEncodingFails_thenReturnsEncodingFailure() async throws {
        struct Bad: Encodable {
            func encode(to encoder: Encoder) throws {
                throw NSError(domain: "EncodingFail", code: 1234)
            }
        }
        let session = MockHTTPSession(scenario: .error(NSError(domain: "n/a", code: 0)))
        let client = makeClient(session: session)
        let bad = Bad()
        let result = await client.post("/encode", body: bad)
        switch result {
        case .failure(let failure):
            if case .encoding = failure {
                // pass
            } else {
                XCTFail("Expected .encoding failure")
            }
        default:
            XCTFail("Expected failure")
        }
    }
    
    func test_givenHeaders_whenRequest_thenMergedWithDefaultHeaders() async throws {
        // Given
        let (data, response) = makeMockResponse(statusCode: 200)
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session, defaultHeaders: ["X-Default": "1"])
        var capturedHeaders: [String: String]?
        session.onRequest = { request in
            capturedHeaders = request.allHTTPHeaderFields
            return (data, response)
        }
        
        // When
        let _ = await client.get("/path", headers: ["X-Custom": "2"])
        
        // Then
        XCTAssertEqual(capturedHeaders?["X-Default"], "1")
        XCTAssertEqual(capturedHeaders?["X-Custom"], "2")
    }
    
    func test_givenPostWithData_whenSuccess_thenReturnsSuccess() async throws {
        // Given
        let (data, response) = makeMockResponse(statusCode: 201)
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let body = Data("body".utf8)
        
        // When
        let result = await client.post("/create", data: body)
        
        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, data)
            XCTAssertEqual(success.response.statusCode, 201)
        default:
            XCTFail("Expected success")
        }
    }
    
    func test_givenPutPatchDelete_whenSuccess_thenReturnsSuccess() async throws {
        // Given
        let (data, response) = makeMockResponse(statusCode: 204)
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let body = Data("x".utf8)
        
        // When
        let putResult = await client.put("/resource", body: body)
        let patchResult = await client.patch("/resource", body: body)
        let deleteResult = await client.delete("/resource", body: body)
        
        // Then
        for result in [putResult, patchResult, deleteResult] {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.data, data)
                XCTAssertEqual(success.response.statusCode, 204)
            default:
                XCTFail("Expected success")
            }
        }
    }
    
    func test_givenQueryItemsAndFragment_whenGet_thenURLIncludesQueryAndFragment() async throws {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        var capturedURL: URL?
        session.onRequest = { request in
            capturedURL = request.url
            return (data, response)
        }
        
        // When
        let _ = await client.get(
            "/resource",
            queryItems: ["foo": "bar", "x": "y"],
            fragment: "frag"
        )
        
        // Then
        XCTAssertNotNil(capturedURL)
        let urlString = capturedURL!.absoluteString
        // Query order is not guaranteed
        let expected1 = "https://host.com/resource?foo=bar&x=y#frag"
        let expected2 = "https://host.com/resource?x=y&foo=bar#frag"
        XCTAssertTrue(urlString == expected1 || urlString == expected2)
    }
    
    func test_givenCustomPort_whenClientInitializes_thenURLIncludesPort() async throws {
        // Given
        let (data, response) = makeMockResponse()
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(host: "https://host.com:8888", session: session)
        var capturedURL: URL?
        session.onRequest = { request in
            capturedURL = request.url
            return (data, response)
        }
        
        // When
        let _ = await client.get("/resource")
        
        // Then
        XCTAssertNotNil(capturedURL)
        XCTAssertTrue(capturedURL!.absoluteString.contains(":8888"))
    }

    func test_givenEncodablePost_whenEncodingSucceeds_thenCallsPostWithData() async throws {
        struct Good: Encodable {
            let value: String
        }
        let (data, response) = makeMockResponse(statusCode: 201)
        let session = MockHTTPSession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let good = Good(value: "abc")
        
        let result = await client.post("/encode", body: good)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, data)
            XCTAssertEqual(success.response.statusCode, 201)
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenBadHost_whenInit_thenIsValidIsFalse() async {
        // Given: Empty string host causes isValid = false in the catch branch
        let client = SwiftHTTPClient(host: "")
        // Then
        let mirror = Mirror(reflecting: client)
        let hasValidHost = mirror.descendant("hasValidHost") as? Bool
        XCTAssertEqual(hasValidHost, false)
    }

}
