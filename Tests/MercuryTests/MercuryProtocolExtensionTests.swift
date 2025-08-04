//
//  MercuryProtocolExtensionTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//

import XCTest
@testable import Mercury

final class MercuryProtocolExtensionTests: XCTestCase {

    struct DummyResponse: Codable, Equatable { let foo: String }
    struct DummyBody: Codable, Equatable { let bar: String }

    private var mock: MockMercury!
    private var mercury: MercuryProtocol!

    override func setUp() {
        super.setUp()
        mock = MockMercury()
        mercury = mock
        mock.reset()
    }

    override func tearDown() {
        mock = nil
        mercury = nil
        super.tearDown()
    }

    // MARK: - GET

    func test_givenDefaults_whenGetCalledViaProtocol_thenExtensionIsCovered() async {
        // Given
        mock.stubGet(path: "/test", response: DummyResponse(foo: "bar"))

        // When
        let result = await mercury.get(
            path: "/test",
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .GET, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "bar")
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - POST

    func test_givenDefaults_whenPostCalledViaProtocol_thenExtensionIsCovered() async {
        // Given
        mock.stubPost(path: "/test", response: DummyResponse(foo: "baz"))

        // When
        let result = await mercury.post(
            path: "/test",
            body: DummyBody(bar: "baz"),
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .POST, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "baz")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenDefaults_whenPostCalledViaProtocolWithoutBody_thenExtensionIsCovered() async {
        // Given
        mock.stubPost(path: "/test", response: DummyResponse(foo: "no-body"))

        // When
        let result = await mercury.post(
            path: "/test",
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .POST, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "no-body")
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - PUT

    func test_givenDefaults_whenPutCalledViaProtocol_thenExtensionIsCovered() async {
        // Given
        mock.stubPut(path: "/test", response: DummyResponse(foo: "put"))

        // When
        let result = await mercury.put(
            path: "/test",
            body: DummyBody(bar: "put"),
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .PUT, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "put")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenDefaults_whenPutCalledViaProtocolWithoutBody_thenExtensionIsCovered() async {
        // Given
        mock.stubPut(path: "/test", response: DummyResponse(foo: "no-body-put"))

        // When
        let result = await mercury.put(
            path: "/test",
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .PUT, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "no-body-put")
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - PATCH

    func test_givenDefaults_whenPatchCalledViaProtocol_thenExtensionIsCovered() async {
        // Given
        mock.stubPatch(path: "/test", response: DummyResponse(foo: "patch"))

        // When
        let result = await mercury.patch(
            path: "/test",
            body: DummyBody(bar: "patch"),
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .PATCH, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "patch")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenDefaults_whenPatchCalledViaProtocolWithoutBody_thenExtensionIsCovered() async {
        // Given
        mock.stubPatch(path: "/test", response: DummyResponse(foo: "no-body-patch"))

        // When
        let result = await mercury.patch(
            path: "/test",
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .PATCH, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "no-body-patch")
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - DELETE

    func test_givenDefaults_whenDeleteCalledViaProtocol_thenExtensionIsCovered() async {
        // Given
        mock.stubDelete(path: "/test", response: DummyResponse(foo: "delete"))

        // When
        let result = await mercury.delete(
            path: "/test",
            body: DummyBody(bar: "delete"),
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .DELETE, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "delete")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenDefaults_whenDeleteCalledViaProtocolWithoutBody_thenExtensionIsCovered() async {
        // Given
        mock.stubDelete(path: "/test", response: DummyResponse(foo: "no-body-delete"))

        // When
        let result = await mercury.delete(
            path: "/test",
            responseType: DummyResponse.self
        )

        // Then
        XCTAssertEqual(mock.callCount(for: .DELETE, path: "/test"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.foo, "no-body-delete")
        case .failure:
            XCTFail("Expected success")
        }
    }
}
