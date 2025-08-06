//
//  MercuryProtocol_NoBody_Tests.swift
//  MercuryTests
//

import XCTest
@testable import Mercury
@testable import MercuryTesting

final class MercuryProtocol_NoBody_Tests: XCTestCase {
    
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

    func test_givenNoBodyExtensions_whenCalled_thenDelegatesWithNilBody() async {
        // Given
        mock.stubPost(path: "/nobody", response: DummyResponse(foo: "post"))
        mock.stubPut(path: "/nobody", response: DummyResponse(foo: "put"))
        mock.stubPatch(path: "/nobody", response: DummyResponse(foo: "patch"))
        mock.stubDelete(path: "/nobody", response: DummyResponse(foo: "delete"))

        let mercury: MercuryProtocol = mock

        // When
        let postResult = await mercury.post(path: "/nobody", responseType: DummyResponse.self)
        let putResult = await mercury.put(path: "/nobody", responseType: DummyResponse.self)
        let patchResult = await mercury.patch(path: "/nobody", responseType: DummyResponse.self)
        let deleteResult = await mercury.delete(path: "/nobody", responseType: DummyResponse.self)

        // Then
        let results = [
            ("post", postResult), ("put", putResult), ("patch", patchResult), ("delete", deleteResult)
        ]
        for (expected, result) in results {
            switch result {
            case .success(let success):
                XCTAssertEqual(success.data.foo, expected)
            case .failure:
                XCTFail("Expected success for \(expected)")
            }
        }
    }

    func test_givenNoBodyExtensions_whenPassingAllParameters_thenDelegatesCorrectly() async {
        // Given
        mock.stubPost(path: "/params", response: DummyResponse(foo: "post"))
        let mercury: MercuryProtocol = mock
        let headers = ["h": "1"]
        let query = ["q": "x"]
        let fragment = "frag"
        let cache: URLRequest.CachePolicy = .reloadIgnoringCacheData

        // When
        let _ = await mercury.post(
            path: "/params",
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cache,
            responseType: DummyResponse.self
        )
        
        // Then
        let last = mock.recordedCalls.last
        XCTAssertEqual(last?.headers, headers)
        XCTAssertEqual(last?.query, query)
        XCTAssertEqual(last?.fragment, fragment)
        XCTAssertEqual(last?.cachePolicy, cache)
    }
}
