//
//  MercuryProtocolTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//

import XCTest
@testable import Mercury
@testable import MercuryTesting

final class MercuryProtocolTests: XCTestCase {

    struct DummyResponse: Codable, Equatable { let foo: String }
    struct DummyBody: Codable, Equatable { let bar: String }
    
    struct OtherBody: Codable, Equatable { let baz: Int }

    private var mock: MockMercury!

    override func setUp() {
        super.setUp()
        mock = MockMercury()
    }

    override func tearDown() {
        mock = nil
        super.tearDown()
    }

    func test_givenProtocolExtensions_whenCalledWithDefaults_thenWork() async {
        // Given
        mock.stubGet(path: "/test", response: DummyResponse(foo: "get"))
        mock.stubPost(path: "/test", response: DummyResponse(foo: "post"))
        mock.stubPut(path: "/test", response: DummyResponse(foo: "put"))
        mock.stubPatch(path: "/test", response: DummyResponse(foo: "patch"))
        mock.stubDelete(path: "/test", response: DummyResponse(foo: "delete"))

        let mercury: MercuryProtocol = mock

        // When/Then - Test default parameter extensions
        let getResult = await mercury.get(path: "/test", responseType: DummyResponse.self)
        let postResult = await mercury.post(path: "/test", responseType: DummyResponse.self)
        let putResult = await mercury.put(path: "/test", responseType: DummyResponse.self)
        let patchResult = await mercury.patch(path: "/test", responseType: DummyResponse.self)
        let deleteResult = await mercury.delete(path: "/test", responseType: DummyResponse.self)

        for (method, result) in [("GET", getResult), ("POST", postResult), ("PUT", putResult), ("PATCH", patchResult), ("DELETE", deleteResult)] {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.value.foo, method.lowercased(), "Failed for \(method)")
            case .failure:
                XCTFail("Expected success for \(method)")
            }
        }
    }

    // MARK: - Missing coverage below

    func test_givenAllVerbsWithBody_whenCalledWithAllParams_thenReturnExpectedResponses() async {
        // Given
        let allParams: (headers: [String: String], query: [String: String], fragment: String, cache: URLRequest.CachePolicy) =
            (["X": "1"], ["y": "2"], "fragment", .reloadIgnoringLocalCacheData)
        let body = DummyBody(bar: "body")
        let mercury: MercuryProtocol = mock

        mock.stubPost(path: "/explicit", response: DummyResponse(foo: "POST"))
        mock.stubPut(path: "/explicit", response: DummyResponse(foo: "PUT"))
        mock.stubPatch(path: "/explicit", response: DummyResponse(foo: "PATCH"))
        mock.stubDelete(path: "/explicit", response: DummyResponse(foo: "DELETE"))

        // When
        let postResult = await mercury.post(
            path: "/explicit",
            body: body,
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let putResult = await mercury.put(
            path: "/explicit",
            body: body,
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let patchResult = await mercury.patch(
            path: "/explicit",
            body: body,
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let deleteResult = await mercury.delete(
            path: "/explicit",
            body: body,
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )

        // Then
        let tuples = [("POST", postResult), ("PUT", putResult), ("PATCH", patchResult), ("DELETE", deleteResult)]
        for (expected, result) in tuples {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.value.foo, expected, "Expected \(expected) for \(expected)")
            case .failure:
                XCTFail("Expected success for \(expected)")
            }
        }
    }

    func test_givenAllVerbsWithoutBody_whenCalledWithAllParams_thenReturnExpectedResponses() async {
        // Given
        let allParams: (headers: [String: String], query: [String: String], fragment: String, cache: URLRequest.CachePolicy) =
            (["X": "1"], ["y": "2"], "fragment", .reloadIgnoringLocalCacheData)
        let mercury: MercuryProtocol = mock

        mock.stubGet(path: "/explicit", response: DummyResponse(foo: "GET"))
        mock.stubPost(path: "/explicit", response: DummyResponse(foo: "POST"))
        mock.stubPut(path: "/explicit", response: DummyResponse(foo: "PUT"))
        mock.stubPatch(path: "/explicit", response: DummyResponse(foo: "PATCH"))
        mock.stubDelete(path: "/explicit", response: DummyResponse(foo: "DELETE"))

        // When
        let getResult = await mercury.get(
            path: "/explicit",
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let postResult = await mercury.post(
            path: "/explicit",
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let putResult = await mercury.put(
            path: "/explicit",
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let patchResult = await mercury.patch(
            path: "/explicit",
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )
        let deleteResult = await mercury.delete(
            path: "/explicit",
            headers: allParams.headers,
            query: allParams.query,
            fragment: allParams.fragment,
            cachePolicy: allParams.cache,
            responseType: DummyResponse.self
        )

        // Then
        let tuples = [
            ("GET", getResult), ("POST", postResult), ("PUT", putResult), ("PATCH", patchResult), ("DELETE", deleteResult)
        ]
        for (expected, result) in tuples {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.value.foo, expected, "Expected \(expected) for \(expected)")
            case .failure:
                XCTFail("Expected success for \(expected)")
            }
        }
    }

    func test_givenPostPutPatchDelete_whenCalledWithOtherBodyType_thenUsesCorrectTypeAndReturnsSuccess() async {
        // Given
        let body = OtherBody(baz: 42)
        mock.stubPost(path: "/other", response: DummyResponse(foo: "other_post"))
        mock.stubPut(path: "/other", response: DummyResponse(foo: "other_put"))
        mock.stubPatch(path: "/other", response: DummyResponse(foo: "other_patch"))
        mock.stubDelete(path: "/other", response: DummyResponse(foo: "other_delete"))
        let mercury: MercuryProtocol = mock

        // When
        let postResult = await mercury.post(path: "/other", body: body, responseType: DummyResponse.self)
        let putResult = await mercury.put(path: "/other", body: body, responseType: DummyResponse.self)
        let patchResult = await mercury.patch(path: "/other", body: body, responseType: DummyResponse.self)
        let deleteResult = await mercury.delete(path: "/other", body: body, responseType: DummyResponse.self)

        // Then
        let results = [
            ("other_post", postResult),
            ("other_put", putResult),
            ("other_patch", patchResult),
            ("other_delete", deleteResult)
        ]
        for (expected, result) in results {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.value.foo, expected)
            case .failure:
                XCTFail("Expected success for \(expected)")
            }
        }
    }

    func test_givenProtocolExtensions_whenCalledWithBodyNilExplicitly_thenDoesNotCrashAndReturnsSuccess() async {
        // Given
        mock.stubPost(path: "/body_nil", response: DummyResponse(foo: "nil"))
        mock.stubPut(path: "/body_nil", response: DummyResponse(foo: "nil"))
        mock.stubPatch(path: "/body_nil", response: DummyResponse(foo: "nil"))
        mock.stubDelete(path: "/body_nil", response: DummyResponse(foo: "nil"))

        let mercury: MercuryProtocol = mock

        // When
        let postResult = await mercury.post(path: "/body_nil", body: Optional<DummyBody>.none, responseType: DummyResponse.self)
        let putResult = await mercury.put(path: "/body_nil", body: Optional<DummyBody>.none, responseType: DummyResponse.self)
        let patchResult = await mercury.patch(path: "/body_nil", body: Optional<DummyBody>.none, responseType: DummyResponse.self)
        let deleteResult = await mercury.delete(path: "/body_nil", body: Optional<DummyBody>.none, responseType: DummyResponse.self)

        // Then
        let results = [
            ("nil", postResult), ("nil", putResult), ("nil", patchResult), ("nil", deleteResult)
        ]
        for (expected, result) in results {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.value.foo, expected)
            case .failure:
                XCTFail("Expected success for \(expected)")
            }
        }
    }

    func test_givenProtocolMethods_whenFailureIsStubbed_thenReturnsFailure() async {
        // Given
        mock.stubFailure(method: .GET, path: "/fail", error: .server(statusCode: 500, data: nil), responseType: DummyResponse.self)
        mock.stubFailure(method: .POST, path: "/fail", error: .server(statusCode: 500, data: nil), responseType: DummyResponse.self)
        mock.stubFailure(method: .PUT, path: "/fail", error: .server(statusCode: 500, data: nil), responseType: DummyResponse.self)
        mock.stubFailure(method: .PATCH, path: "/fail", error: .server(statusCode: 500, data: nil), responseType: DummyResponse.self)
        mock.stubFailure(method: .DELETE, path: "/fail", error: .server(statusCode: 500, data: nil), responseType: DummyResponse.self)

        let mercury: MercuryProtocol = mock

        // When
        let getResult = await mercury.get(path: "/fail", responseType: DummyResponse.self)
        let postResult = await mercury.post(path: "/fail", responseType: DummyResponse.self)
        let putResult = await mercury.put(path: "/fail", responseType: DummyResponse.self)
        let patchResult = await mercury.patch(path: "/fail", responseType: DummyResponse.self)
        let deleteResult = await mercury.delete(path: "/fail", responseType: DummyResponse.self)

        // Then
        for (verb, result) in [("GET", getResult), ("POST", postResult), ("PUT", putResult), ("PATCH", patchResult), ("DELETE", deleteResult)] {
            switch result {
            case .success:
                XCTFail("Expected failure for \(verb)")
            case .failure(let error):
                if case .server(let code, _) = error.error {
                    XCTAssertEqual(code, 500)
                } else {
                    XCTFail("Expected server error")
                }
            }
        }
    }
}

