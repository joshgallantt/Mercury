//
//  MercuryProtocol_Optionals_Tests.swift
//  MercuryTests
//

import XCTest
@testable import Mercury
@testable import MercuryTesting

final class MercuryProtocol_Optionals_Tests: XCTestCase {

    private struct DummyBody: Codable, Equatable { let a: Int }
    private struct DummyResponse: Codable, Equatable { let foo: String }
    private var mock: MockMercury!

    override func setUp() {
        super.setUp()
        mock = MockMercury()
    }

    override func tearDown() {
        mock = nil
        super.tearDown()
    }

    func test_givenOptionalsExtensions_whenCalledWithSome_thenDelegatesWithCorrectParameters() async {
        // Given
        mock.stubPost(path: "/optionals", response: DummyResponse(foo: "yes"))
        let mercury: MercuryProtocol = mock
        let body = DummyBody(a: 2)
        let headers = ["key": "val"]
        let query = ["a": "b"]
        let fragment = "frag"
        let cache: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData

        // When
        let result = await mercury.post(
            path: "/optionals",
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cache,
            responseType: DummyResponse.self
        )

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data.foo, "yes")
        case .failure:
            XCTFail("Expected success")
        }

        // Parameter forwarding check
        let last = mock.recordedCalls.last
        XCTAssertEqual(last?.headers, headers)
        XCTAssertEqual(last?.query, query)
        XCTAssertEqual(last?.fragment, fragment)
        XCTAssertEqual(last?.cachePolicy, cache)
    }

    func test_givenOptionalsExtensions_whenCalledWithNone_thenDelegatesCorrectlyAndDoesNotCrash() async {
        // Given
        mock.stubPost(path: "/optionalsnil", response: DummyResponse(foo: "nil"))
        let mercury: MercuryProtocol = mock

        // When
        let result = await mercury.post(
            path: "/optionalsnil",
            body: Optional<DummyBody>.none,
            responseType: DummyResponse.self
        )

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.data.foo, "nil")
        case .failure:
            XCTFail("Expected success")
        }
    }
}
