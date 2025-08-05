//
//  MercuryProtocolExtensionTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury

final class MercuryProtocolExtensionTests: XCTestCase {

    struct DummyResponse: Codable, Equatable { let foo: String }
    struct DummyBody: Codable, Equatable { let bar: String }

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
}
