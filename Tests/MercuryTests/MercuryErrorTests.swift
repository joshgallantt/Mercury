//
//  MercuryErrorTests.swift
//  MercuryTests
//
//  Created by Josh Gallant on 12/07/2025.
//

import XCTest
@testable import Mercury

final class MercuryErrorTests: XCTestCase {

    // MARK: - Helper Error
    struct MockError: Error, LocalizedError {
        var errorDescription: String? { "Mock error description" }
    }

    // MARK: - invalidURL
    func test_givenInvalidURL_whenDescription_thenReturnsExpectedString() {
        // Given
        let error = MercuryError.invalidURL

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "Invalid URL")
    }

    // MARK: - server(statusCode:data:)
    func test_givenServer400WithData_whenDescription_thenReturnsExpectedStringWithBody() {
        // Given
        let body = "Bad input".data(using: .utf8)
        let error = MercuryError.server(statusCode: 400, data: body)

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "400 Bad Request: Bad input")
    }

    func test_givenServer401WithoutData_whenDescription_thenReturnsExpectedStringWithoutBody() {
        // Given
        let error = MercuryError.server(statusCode: 401, data: nil)

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "401 Unauthorized")
    }

    func test_givenServerWithUnknownStatusAndNoData_whenDescription_thenReturnsGenericServerString() {
        // Given
        let error = MercuryError.server(statusCode: 418, data: nil) // Teapot!

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "Server returned status code 418")
    }

    func test_givenServerWithDataButEmptyString_whenDescription_thenReturnsStatusWithoutBody() {
        // Given
        let error = MercuryError.server(statusCode: 404, data: Data())

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "404 Not Found")
    }

    func test_givenServerWithNonUTF8Data_whenDescription_thenReturnsStatusWithoutBody() {
        // Given
        let data = Data([0xFF, 0xD8, 0xFF]) // Invalid UTF-8
        let error = MercuryError.server(statusCode: 500, data: data)

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "500 Internal Server Error")
    }

    // MARK: - invalidResponse
    func test_givenInvalidResponse_whenDescription_thenReturnsExpectedString() {
        // Given
        let error = MercuryError.invalidResponse

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "Invalid or unexpected response from server")
    }

    // MARK: - transport
    func test_givenTransportError_whenDescription_thenReturnsExpectedString() {
        // Given
        let error = MercuryError.transport(MockError())

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "Transport error: Mock error description")
    }

    // MARK: - encoding
    func test_givenEncodingError_whenDescription_thenReturnsExpectedString() {
        // Given
        let error = MercuryError.encoding(MockError())

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "Encoding error: Mock error description")
    }

    // MARK: - decoding
    func test_givenDecodingFailed_whenDescription_thenReturnsExpectedString() {
        // Given
        let error = MercuryError.decoding(namespace: "User", key: "name", underlyingError: MockError())

        // When
        let description = error.description

        // Then
        XCTAssertEqual(description, "Decoding failed in 'User' for key 'name': Mock error description")
    }
}
