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

    func test_givenSuccessStatus_whenGet_thenReturnsHTTPSuccess_andIncludesSignature() async {
        let (data, response) = makeMockResponse(statusCode: 200, body: "yay")
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get("/api/test")

        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, data)
            XCTAssertEqual(success.response.statusCode, 200)
            XCTAssertFalse(success.requestSignature.isEmpty)
        default:
            XCTFail("Expected success")
        }
    }

    func test_givenNonSuccessStatus_whenGet_thenReturnsServerFailure_withSignature() async {
        let (data, response) = makeMockResponse(statusCode: 404, body: "not found")
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)

        let result = await client.get("/api/test")

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

        let result = await client.get("/api/test")

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

        let result = await client.get("/api/test")

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

        let result = await client.get("/path")

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
            let result = await client.get("/stable")
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

        _ = await client.get("/path", headers: ["X-Custom": "2"])

        XCTAssertEqual(capturedHeaders?["X-Default"], "1")
        XCTAssertEqual(capturedHeaders?["X-Custom"], "2")
    }

    func test_givenPostWithData_whenSuccess_thenReturnsSuccess_andIncludesSignature() async {
        let (data, response) = makeMockResponse(statusCode: 201)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let body = Data("body".utf8)

        let result = await client.post("/create", data: body)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, data)
            XCTAssertEqual(success.response.statusCode, 201)
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
            await client.put("/resource", body: body),
            await client.patch("/resource", body: body),
            await client.delete("/resource", body: body)
        ] {
            switch call {
            case .success(let success):
                XCTAssertEqual(success.data, data)
                XCTAssertEqual(success.response.statusCode, 204)
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
            "/resource",
            queryItems: ["foo": "bar", "x": "y"],
            fragment: "frag"
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

        _ = await client.get("/resource")

        XCTAssertNotNil(capturedURL)
        XCTAssertTrue(capturedURL!.absoluteString.contains(":8888"))
    }

    func test_givenEncodablePost_whenEncodingSucceeds_thenCallsPostWithData_andIncludesSignature() async {
        struct Good: Encodable { let value: String }
        let (data, response) = makeMockResponse(statusCode: 201)
        let session = MockMercurySession(scenario: .success(data, response))
        let client = makeClient(session: session)
        let good = Good(value: "abc")

        let result = await client.post("/encode", body: good)

        switch result {
        case .success(let success):
            XCTAssertEqual(success.data, data)
            XCTAssertEqual(success.response.statusCode, 201)
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
        let result = await client.post("/encode", body: Bad())
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

    func test_givenBadHost_whenInit_thenIsValidIsFalse() async {
        let client = Mercury(host: "")
        let mirror = Mirror(reflecting: client)
        let hasValidHost = mirror.descendant("hasValidHost") as? Bool
        XCTAssertEqual(hasValidHost, false)
    }
}
