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
        let requestString = "GET|https://example.com|headers:accept:application/json"
        let requestSignature = requestString + "hash"

        // When
        let success = MercurySuccess(
            value: user,
            httpResponse: response,
            requestString: requestString,
            requestSignature: requestSignature
        )

        // Then
        XCTAssertEqual(success.data, user)
        XCTAssertEqual(success.httpResponse.statusCode, 200)
        XCTAssertEqual(success.requestString, requestString)
        XCTAssertFalse(success.requestSignature.isEmpty)
    }

    func test_givenMercuryFailure_whenInit_thenPropertiesAreSet() {
        // Given
        let error = MercuryError.server(statusCode: 500, data: nil)
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        let requestString = "POST|https://example.com/users"
        let requestSig = requestString + "hash"

        // When
        let failure = MercuryFailure(
            error: error,
            httpResponse: response,
            requestString: requestString,
            requestSignature: requestSig
        )

        // Then
        XCTAssertEqual(failure.description, "500 Internal Server Error")
        XCTAssertEqual(failure.httpResponse, response)
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertFalse(failure.requestSignature.isEmpty)
    }
}
