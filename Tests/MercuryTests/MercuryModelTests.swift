//
//  MercuryModelTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury

final class MercuryModelTests: XCTestCase {
    
    func test_givenMercurySuccess_whenInit_thenPropertiesAreSet() {
        // Given
        struct User: Decodable, Equatable { let id: Int; let name: String }
        let user = User(id: 42, name: "Test")
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // When
        let success = MercurySuccess(
            value: user,
            httpResponse: response
        )

        // Then
        XCTAssertEqual(success.data, user)
        XCTAssertEqual(success.httpResponse.statusCode, 200)
    }

    func test_givenMercuryFailure_whenInit_thenPropertiesAreSet() {
        // Given
        let error = MercuryError.server(statusCode: 500, data: nil)
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!

        // When
        let failure = MercuryFailure(
            error: error,
            httpResponse: response
        )

        // Then
        XCTAssertEqual(failure.description, "500 Internal Server Error")
        XCTAssertEqual(failure.httpResponse, response)
    }
}
