//
//  MercuryProtocol_NoResponse_Tests.swift
//  MercuryTests
//

import XCTest
@testable import Mercury
@testable import MercuryTesting

final class MercuryProtocol_NoResponse_Tests: XCTestCase {

    private struct DummyBody: Codable, Equatable { let bar: String }
    private var mock: MockMercury!

    override func setUp() {
        super.setUp()
        mock = MockMercury()
    }

    override func tearDown() {
        mock = nil
        super.tearDown()
    }

    func test_givenNoResponseExtensions_whenCalledWithBody_thenDelegatesToResponseTypeData() async {
        // Given
        let body = DummyBody(bar: "b")
        mock.stubPost(path: "/noresp", response: Data("abc".utf8))
        mock.stubPut(path: "/noresp", response: Data("def".utf8))
        mock.stubPatch(path: "/noresp", response: Data("ghi".utf8))
        mock.stubDelete(path: "/noresp", response: Data("jkl".utf8))
        let mercury: MercuryProtocol = mock

        // When
        let postResult = await mercury.post(path: "/noresp", body: body)
        let putResult = await mercury.put(path: "/noresp", body: body)
        let patchResult = await mercury.patch(path: "/noresp", body: body)
        let deleteResult = await mercury.delete(path: "/noresp", body: body)

        // Then
        for result in [postResult, putResult, patchResult, deleteResult] {
            switch result {
            case .success(let success):
                XCTAssertFalse(success.data.isEmpty)
            case .failure:
                XCTFail("Expected success")
            }
        }
    }
    
    func test_givenNoResponseExtensions_whenAllParametersPassed_thenAllParametersAreForwarded() async {
        // Given
        mock.stubPost(path: "/params", response: Data())
        let mercury: MercuryProtocol = mock
        let body = DummyBody(bar: "body")
        let headers = ["a": "b"]
        let query = ["z": "q"]
        let fragment = "frag"
        let cache: URLRequest.CachePolicy = .returnCacheDataElseLoad

        // When
        _ = await mercury.post(
            path: "/params",
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cache
        )
        
        // Then
        let last = mock.recordedCalls.last
        XCTAssertEqual(last?.headers, headers)
        XCTAssertEqual(last?.query, query)
        XCTAssertEqual(last?.fragment, fragment)
        XCTAssertEqual(last?.cachePolicy, cache)
    }
}
