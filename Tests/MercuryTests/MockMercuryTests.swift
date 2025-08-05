//
//  MockMercuryTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury
@testable import MercuryTesting

final class MockMercuryTests: XCTestCase {

    struct User: Codable, Equatable {
        let id: Int
        let name: String
    }

    private var mock: MockMercury!

    override func setUp() {
        super.setUp()
        mock = MockMercury()
    }

    override func tearDown() {
        mock.reset()
        mock = nil
        super.tearDown()
    }

    func test_givenStubbedGet_whenCalled_thenReturnsStub_andRecordsCall() async {
        // Given
        let user = User(id: 1, name: "Alice")
        mock.stubGet(path: "/users/1", response: user)

        // When
        let result = await mock.get(path: "/users/1", responseType: User.self)

        // Then
        XCTAssertTrue(mock.wasCalled(method: .GET, path: "/users/1"))
        XCTAssertEqual(mock.callCount(for: .GET, path: "/users/1"), 1)
        let call = mock.recordedCalls.first
        XCTAssertEqual(call?.method, .GET)
        XCTAssertEqual(call?.path, "/users/1")
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, user)
        case .failure(let failure):
            XCTFail("Expected success, got failure: \(failure)")
        }
    }

    func test_givenStubbedPost_whenCalled_thenReturnsStub_andRecordsCall() async {
        // Given
        let newUser = User(id: 2, name: "Bob")
        mock.stubPost(path: "/users", response: newUser)

        // When
        let result = await mock.post(path: "/users", body: nil as User?, responseType: User.self)

        // Then
        XCTAssertTrue(mock.wasCalled(method: .POST, path: "/users"))
        XCTAssertEqual(mock.callCount(for: .POST, path: "/users"), 1)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, newUser)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenStubbedPutPatchDelete_whenCalled_thenReturnsStubs() async {
        // Given
        let updatedUser = User(id: 3, name: "Charlie")
        mock.stubPut(path: "/users/3", response: updatedUser)
        mock.stubPatch(path: "/users/3", response: updatedUser)
        mock.stubDelete(path: "/users/3", response: updatedUser)

        // When
        let putResult = await mock.put(path: "/users/3", body: updatedUser, responseType: User.self)
        let patchResult = await mock.patch(path: "/users/3", body: updatedUser, responseType: User.self)
        let deleteResult = await mock.delete(path: "/users/3", body: updatedUser, responseType: User.self)

        // Then
        switch putResult {
        case .success(let s): XCTAssertEqual(s.value, updatedUser)
        case .failure: XCTFail("Expected success for PUT")
        }
        switch patchResult {
        case .success(let s): XCTAssertEqual(s.value, updatedUser)
        case .failure: XCTFail("Expected success for PATCH")
        }
        switch deleteResult {
        case .success(let s): XCTAssertEqual(s.value, updatedUser)
        case .failure: XCTFail("Expected success for DELETE")
        }
        XCTAssertEqual(mock.callCount(for: .PUT, path: "/users/3"), 1)
        XCTAssertEqual(mock.callCount(for: .PATCH, path: "/users/3"), 1)
        XCTAssertEqual(mock.callCount(for: .DELETE, path: "/users/3"), 1)
    }

    func test_givenStubbedFailure_whenCalled_thenReturnsFailure_andRecordsCall() async {
        // Given
        mock.stubFailure(method: .GET, path: "/fail", error: .server(statusCode: 500, data: nil), responseType: User.self)

        // When
        let result = await mock.get(path: "/fail", responseType: User.self)

        // Then
        XCTAssertTrue(mock.wasCalled(method: .GET, path: "/fail"))
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let failure):
            if case .server(let code, _) = failure.error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected server error")
            }
        }
    }

    func test_givenNoStub_whenCalled_thenReturnsInvalidURLFailure() async {
        // When
        let result = await mock.get(path: "/notstubbed", responseType: User.self)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let failure):
            if case .invalidURL = failure.error {
                // Success!
            } else {
                XCTFail("Expected invalidURL error")
            }
        }
    }

    func test_givenMultipleStubs_whenCalledWithDifferentPaths_thenEachStubIsIsolated() async {
        // Given
        let alice = User(id: 1, name: "Alice")
        let bob = User(id: 2, name: "Bob")
        mock.stubGet(path: "/users/1", response: alice)
        mock.stubGet(path: "/users/2", response: bob)

        // When
        let aliceResult = await mock.get(path: "/users/1", responseType: User.self)
        let bobResult = await mock.get(path: "/users/2", responseType: User.self)

        // Then
        switch (aliceResult, bobResult) {
        case (.success(let a), .success(let b)):
            XCTAssertEqual(a.value, alice)
            XCTAssertEqual(b.value, bob)
        default:
            XCTFail("Expected both stubs to succeed")
        }
    }

    func test_givenStubbedWithDelay_whenCalled_thenWaitsBeforeReturning() async {
        // Given
        let user = User(id: 42, name: "Waiter")
        mock.stubGet(path: "/delayed", response: user, delay: 0.1)

        // When
        let start = Date()
        _ = await mock.get(path: "/delayed", responseType: User.self)
        let elapsed = Date().timeIntervalSince(start)

        // Then
        XCTAssertGreaterThanOrEqual(elapsed, 0.1)
    }

    func test_givenStubbedTwice_whenStubbedAgain_thenLastStubWins() async {
        // Given
        let first = User(id: 1, name: "First")
        let second = User(id: 2, name: "Second")
        mock.stubGet(path: "/dup", response: first)
        mock.stubGet(path: "/dup", response: second)

        // When
        let result = await mock.get(path: "/dup", responseType: User.self)

        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, second, "Last stub should win")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenMultipleCalls_whenRecordedCallsQueried_thenShowsOrderAndParams() async {
        // Given
        let a = User(id: 1, name: "A")
        let b = User(id: 2, name: "B")
        mock.stubGet(path: "/a", response: a)
        mock.stubPost(path: "/b", response: b)

        // When
        _ = await mock.get(path: "/a", responseType: User.self)
        _ = await mock.post(path: "/b", body: nil as User?, headers: ["X-Test": "1"], responseType: User.self)

        // Then
        let calls = mock.recordedCalls
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].method, .GET)
        XCTAssertEqual(calls[1].method, .POST)
        XCTAssertEqual(calls[0].path, "/a")
        XCTAssertEqual(calls[1].path, "/b")
        XCTAssertEqual(calls[1].headers?["X-Test"], "1")
    }

    func test_givenReset_whenCalled_thenClearsAllState() async {
        // Given
        let user = User(id: 9, name: "Temp")
        mock.stubGet(path: "/reset", response: user)
        _ = await mock.get(path: "/reset", responseType: User.self)
        XCTAssertTrue(mock.wasCalled(method: .GET, path: "/reset"))

        // When
        mock.reset()

        // Then
        XCTAssertEqual(mock.recordedCalls.count, 0)
        XCTAssertFalse(mock.wasCalled(method: .GET, path: "/reset"))
        let result = await mock.get(path: "/reset", responseType: User.self)
        switch result {
        case .success:
            XCTFail("Expected failure after reset")
        case .failure(let failure):
            if case .invalidURL = failure.error { /* pass */ }
            else { XCTFail("Expected invalidURL after reset") }
        }
    }
}
