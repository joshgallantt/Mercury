//
//  MercuryErrorTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury

final class MercuryErrorTests: XCTestCase {

    struct MockError: Error, LocalizedError {
        var errorDescription: String? { "Mock error" }
    }

    func test_givenMercuryErrors_whenDescription_thenCorrectDescriptions() {
        // Given/When/Then
        XCTAssertEqual(MercuryError.invalidURL.description, "Invalid URL")
        XCTAssertEqual(MercuryError.server(statusCode: 404, data: nil).description, "404 Not Found")
        XCTAssertEqual(MercuryError.server(statusCode: 400, data: "Bad input".data(using: .utf8)).description, "400 Bad Request: Bad input")
        XCTAssertEqual(MercuryError.invalidResponse.description, "Invalid or unexpected response from server")
        XCTAssertEqual(MercuryError.transport(MockError()).description, "Transport error: Mock error")
        XCTAssertEqual(MercuryError.encoding(MockError()).description, "Encoding error: Mock error")
        XCTAssertEqual(MercuryError.decoding(namespace: "User", key: "name", underlyingError: MockError()).description, "Decoding failed in 'User' for key 'name': Mock error")
    }
}
