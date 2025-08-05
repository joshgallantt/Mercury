//
//  MockMercuryTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury

final class MockMercuryTests: XCTestCase {
    
    struct User: Codable, Equatable {
        let id: Int
        let name: String
    }

    private var mockMercury: MockMercury!
    
    override func setUp() {
        super.setUp()
        mockMercury = Mercury.mock()
    }
    
    override func tearDown() {
        mockMercury = nil
        super.tearDown()
    }
    
    func test_givenMockMercury_whenUsed_thenRecordsCallsAndStubs() async {
        // Given
        let expectedUser = User(id: 123, name: "John")
        mockMercury.stubGet(path: "/users/123", response: expectedUser)
        
        // When
        let result = await mockMercury.get(path: "/users/123", responseType: User.self)
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 1)
        XCTAssertTrue(mockMercury.wasCalled(method: .GET, path: "/users/123"))
        
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, expectedUser)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_givenMockWithFailure_whenCalled_thenReturnsFailure() async {
        // Given
        mockMercury.stubFailure(method: .GET, path: "/error", error: .server(statusCode: 500, data: nil), responseType: User.self)
        
        // When
        let result = await mockMercury.get(path: "/error", responseType: User.self)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let failure):
            if case .server(let statusCode, _) = failure.error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected server error")
            }
        }
    }

    func test_givenMockWithReset_whenReset_thenClearsState() async {
        // Given
        mockMercury.stubGet(path: "/test", response: User(id: 1, name: "Test"))
        _ = await mockMercury.get(path: "/test", responseType: User.self)
        XCTAssertEqual(mockMercury.callCount, 1)
        
        // When
        mockMercury.reset()
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 0)
        let result = await mockMercury.get(path: "/test", responseType: User.self)
        XCTAssertTrue(result.isFailure) // No stub configured after reset
    }
}
