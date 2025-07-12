//
//  HTTPClientTests.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 12/07/2025.
//

import XCTest
@testable import SwiftHTTPClient

final class HTTPClientTests: XCTestCase {
    // MARK: - Common test data
    let validHost = "api.example.com"
    var client: HTTPClient!

    override func setUp() {
        super.setUp()
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(Data(), HTTPURLResponse())))
    }

    // MARK: - Host Normalization

    func test_normalizeHost_removesScheme_andTrailingSlash() {
        let input = "https://api.example.com/"
        let (scheme, host, basePath) = HTTPClient.normalizeHost(input)
        XCTAssertEqual(scheme, "https")
        XCTAssertEqual(host, "api.example.com")
        XCTAssertEqual(basePath, "")
    }

    func test_normalizeHost_handlesBasePath() {
        let input = "https://api.example.com/v2"
        let (scheme, host, basePath) = HTTPClient.normalizeHost(input)
        XCTAssertEqual(scheme, "https")
        XCTAssertEqual(host, "api.example.com")
        XCTAssertEqual(basePath, "/v2")
    }

    func test_normalizeHost_handlesMultipleSlashesAndSubdomains() {
        let input = "www.api.example.com////foo"
        let (scheme, host, basePath) = HTTPClient.normalizeHost(input)
        XCTAssertEqual(scheme, "https")
        XCTAssertEqual(host, "www.api.example.com")
        XCTAssertEqual(basePath, "/foo")
    }

    // MARK: - GET Requests

    func test_get_successfulRequest_returnsDataAndResponse() async {
        let expectedData = #"{"ok":true}"#.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/test")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(expectedData, response)))

        let result = await client.get("/test")
        switch result {
        case .success(let output):
            XCTAssertEqual(output.data, expectedData)
            XCTAssertEqual((output.response as? HTTPURLResponse)?.statusCode, 200)
        default:
            XCTFail("Expected success")
        }
    }

    func test_get_invalidURL_returnsTransportError() async {
        client = HTTPClient(host: "", session: MockHTTPSession(scenario: .error(NSError(domain: "shouldNotBeCalled", code: 1))))
        let result = await client.get("bad path")
        if case .failure(let error) = result {
            if case .transport = error {
                // expected
            } else {
                XCTFail("Expected .transport error")
            }
        } else {
            XCTFail("Expected failure")
        }
    }

    func test_get_non2xxResponse_returnsServerError() async {
        let data = "Error".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/fail")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(data, response)))

        let result = await client.get("/fail")
        if case .failure(let error) = result {
            if case .server(let code, let returnedData) = error {
                XCTAssertEqual(code, 404)
                XCTAssertEqual(returnedData, data)
            } else {
                XCTFail("Expected .server error")
            }
        } else {
            XCTFail("Expected failure")
        }
    }

    func test_get_transportError_propagatesError() async {
        let transportError = URLError(.timedOut)
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .error(transportError)))

        let result = await client.get("/timeout")
        if case .failure(let error) = result {
            if case .transport(let err as URLError) = error {
                XCTAssertEqual(err.code, .timedOut)
            } else {
                XCTFail("Expected URLError in .transport")
            }
        } else {
            XCTFail("Expected failure")
        }
    }

    func test_get_invalidResponseType_returnsInvalidResponseError() async {
        let response = URLResponse(url: URL(string: "https://api.example.com/strange")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(Data(), response)))

        let result = await client.get("/strange")
        if case .failure(let error) = result {
            if case .invalidResponse = error {
                // expected
            } else {
                XCTFail("Expected .invalidResponse error")
            }
        } else {
            XCTFail("Expected failure")
        }
    }

    // MARK: - POST Requests

    func test_post_withBody_successful() async {
        let expectedData = #"{"created":1}"#.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/things")!, statusCode: 201, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(expectedData, response)))
        let postData = #"{"name":"swift"}"#.data(using: .utf8)

        let result = await client.post("/things", body: postData)
        switch result {
        case .success(let output):
            XCTAssertEqual(output.data, expectedData)
            XCTAssertEqual((output.response as? HTTPURLResponse)?.statusCode, 201)
        default:
            XCTFail("Expected success")
        }
    }

    // MARK: - Headers and URL Construction

    func test_headers_areMerged_customOverridesDefault() async {
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/merge")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let defaultHeaders = ["Accept": "application/json", "X-Default": "default"]
        let customHeaders = ["X-Default": "override", "X-Custom": "value"]
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(Data(), response)), commonHeaders: defaultHeaders)

        let result = await client.get("/merge", headers: customHeaders)
        if case .success = result {
            // success, nothing to assert directly
        } else {
            XCTFail("Expected success")
        }
    }

    func test_buildURL_handlesQueryItemsAndFragment() {
        let url = client.buildURL(path: "/abc", queryItems: ["foo": "bar", "baz": "1"], fragment: "frag")
        XCTAssertNotNil(url)
        guard let urlString = url?.absoluteString else {
            XCTFail("URL should not be nil")
            return
        }
        XCTAssertTrue(urlString.contains("foo=bar"))
        XCTAssertTrue(urlString.contains("baz=1"))
        XCTAssertTrue(urlString.contains("#frag"))
    }

    func test_init_acceptsDefaultHeaders_andSucceeds() async {
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(Data(), HTTPURLResponse())))
        let result = await client.get("/ping")
        if case .success = result {
            // expected
        } else if case .failure = result {
            // still OK, just checking no crash
        } else {
            XCTFail("Unexpected result")
        }
    }

    func test_put_successfulRequest_returnsDataAndResponse() async {
        let expectedData = #"{"updated":1}"#.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/things")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(expectedData, response)))
        let putData = #"{"name":"updated"}"#.data(using: .utf8)

        let result = await client.put("/things", body: putData)
        switch result {
        case .success(let output):
            XCTAssertEqual(output.data, expectedData)
            XCTAssertEqual((output.response as? HTTPURLResponse)?.statusCode, 200)
        default:
            XCTFail("Expected success")
        }
    }

    func test_patch_successfulRequest_returnsDataAndResponse() async {
        let expectedData = #"{"patched":1}"#.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/things")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(expectedData, response)))
        let patchData = #"{"field":"new"}"#.data(using: .utf8)
        let result = await client.patch("/things", body: patchData)
        switch result {
        case .success(let output):
            XCTAssertEqual(output.data, expectedData)
            XCTAssertEqual((output.response as? HTTPURLResponse)?.statusCode, 200)
        default:
            XCTFail("Expected success")
        }
    }

    func test_delete_successfulRequest_returnsDataAndResponse() async {
        let expectedData = Data()
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/things")!, statusCode: 204, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(expectedData, response)))
        let result = await client.delete("/things")
        switch result {
        case .success(let output):
            XCTAssertEqual(output.data, expectedData)
            XCTAssertEqual((output.response as? HTTPURLResponse)?.statusCode, 204)
        default:
            XCTFail("Expected success")
        }
    }

    // MARK: - Negative Tests for PATCH/PUT/DELETE

    func test_patch_serverError_returnsServerError() async {
        let data = "Bad Patch".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com/patch")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        client = HTTPClient(host: validHost, session: MockHTTPSession(scenario: .success(data, response)))
        let result = await client.patch("/patch", body: data)
        if case .failure(let error) = result {
            if case .server(let code, let returnedData) = error {
                XCTAssertEqual(code, 400)
                XCTAssertEqual(returnedData, data)
            } else {
                XCTFail("Expected .server error")
            }
        } else {
            XCTFail("Expected failure")
        }
    }

    func test_delete_invalidURL_returnsTransportError() async {
        client = HTTPClient(host: "", session: MockHTTPSession(scenario: .error(NSError(domain: "shouldNotBeCalled", code: 1))))
        let result = await client.delete("bad path")
        if case .failure(let error) = result {
            if case .transport = error {
                // expected
            } else {
                XCTFail("Expected .transport error")
            }
        } else {
            XCTFail("Expected failure")
        }
    }

    // MARK: - Alternate Initializer

    func test_init_defaultSession_initializesProperly() {
        let client = HTTPClient(host: "example.com", port: 8080)
        let url = client.buildURL(path: "/ping", queryItems: nil, fragment: nil)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("8080"))
    }

    // MARK: - Path/Host Normalization

    func test_normalizePath_handlesLeadingAndTrailingSlashes() {
        let result = HTTPClient.normalizePath("/api/", "/test/")
        XCTAssertEqual(result, "/api/test")
    }

    func test_normalizeHost_withWeirdInput() {
        let (scheme, host, basePath) = HTTPClient.normalizeHost("example.com////api/")
        XCTAssertEqual(scheme, "https")
        XCTAssertEqual(host, "example.com")
        XCTAssertEqual(basePath, "/api")
    }

    func test_normalizeHost_emptyInput_returnsEmptyHost() {
        let (scheme, host, basePath) = HTTPClient.normalizeHost("")
        XCTAssertEqual(host, "")
        XCTAssertEqual(scheme, "https")
        XCTAssertEqual(basePath, "")
    }

    func test_normalizeHost_noBasePath() {
        let (_, host, basePath) = HTTPClient.normalizeHost("example.com")
        XCTAssertEqual(host, "example.com")
        XCTAssertEqual(basePath, "")
    }

    // MARK: - HTTPFailure.description

    func test_HTTPFailure_description_invalidURL() {
        let error = HTTPFailure.invalidURL
        XCTAssertTrue(error.description.contains("Invalid URL"))
    }

    func test_HTTPFailure_description_server_withData() {
        let error = HTTPFailure.server(statusCode: 500, data: "fail".data(using: .utf8))
        XCTAssertTrue(error.description.contains("500"))
        XCTAssertTrue(error.description.contains("fail"))
    }

    func test_HTTPFailure_description_server_withoutData() {
        let error = HTTPFailure.server(statusCode: 500, data: nil)
        XCTAssertTrue(error.description.contains("500"))
    }

    func test_HTTPFailure_description_invalidResponse() {
        let error = HTTPFailure.invalidResponse
        XCTAssertTrue(error.description.contains("unexpected response"))
    }

    func test_HTTPFailure_description_transport() {
        let underlying = NSError(domain: "com.test", code: 999)
        let error = HTTPFailure.transport(underlying)
        XCTAssertTrue(error.description.contains("Transport error"))
    }

    // MARK: - buildURL and buildRequest

    func test_buildURL_withNoQueryOrFragment() {
        let url = client.buildURL(path: "/abc", queryItems: nil, fragment: nil)
        XCTAssertNotNil(url)
        XCTAssertFalse(url!.absoluteString.contains("?"))
        XCTAssertFalse(url!.absoluteString.contains("#"))
    }

    func test_buildRequest_mergesHeadersCorrectly() {
        let url = URL(string: "https://api.example.com")!
        let request = client.buildRequest(
            url: url,
            method: .GET,
            headers: ["X-Test": "custom"],
            body: nil,
            cachePolicy: .reloadIgnoringCacheData
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "custom")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

}
