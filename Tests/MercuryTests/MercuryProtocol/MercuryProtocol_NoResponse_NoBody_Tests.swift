//
//  MercuryProtocol_NoResponse_NoBody_Tests.swift
//  MercuryTests
//

import XCTest
@testable import Mercury
@testable import MercuryTesting

final class MercuryProtocol_NoResponse_NoBody_Tests: XCTestCase {

    private var mock: MockMercury!

    override func setUp() {
        super.setUp()
        mock = MockMercury()
    }

    override func tearDown() {
        mock = nil
        super.tearDown()
    }

    func test_givenNoResponseNoBodyExtensions_whenCalled_thenDelegatesToCorrectVerbWithNilBodyAndDataResponseType() async {
        // Given
        mock.stubGet(path: "/get", response: Data([1]))
        mock.stubPost(path: "/post", response: Data([2]))
        mock.stubPut(path: "/put", response: Data([3]))
        mock.stubPatch(path: "/patch", response: Data([4]))
        mock.stubDelete(path: "/delete", response: Data([5]))
        let mercury: MercuryProtocol = mock

        // When
        let getResult = await mercury.get(path: "/get")
        let postResult = await mercury.post(path: "/post")
        let putResult = await mercury.put(path: "/put")
        let patchResult = await mercury.patch(path: "/patch")
        let deleteResult = await mercury.delete(path: "/delete")

        // Then
        let results = [
            getResult, postResult, putResult, patchResult, deleteResult
        ]
        for result in results {
            switch result {
            case .success(let success):
                XCTAssertFalse(success.data.isEmpty)
            case .failure:
                XCTFail("Expected success")
            }
        }
    }

    func test_givenNoResponseNoBodyExtensions_whenParametersArePassed_thenTheyAreForwarded() async {
        // Given
        mock.stubDelete(path: "/params", response: Data())
        let mercury: MercuryProtocol = mock
        let headers = ["k": "v"]
        let query = ["p": "q"]
        let fragment = "frag"
        let cache: URLRequest.CachePolicy = .reloadIgnoringCacheData

        // When
        _ = await mercury.delete(
            path: "/params",
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
