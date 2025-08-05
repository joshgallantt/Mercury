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
        XCTAssertEqual(MercuryError.server(statusCode: 400, data: nil).description, "400 Bad Request")
        XCTAssertEqual(MercuryError.server(statusCode: 400, data: "Bad input".data(using: .utf8)).description, "400 Bad Request: Bad input")
        XCTAssertEqual(MercuryError.server(statusCode: 401, data: nil).description, "401 Unauthorized")
        XCTAssertEqual(MercuryError.server(statusCode: 403, data: nil).description, "403 Forbidden")
        XCTAssertEqual(MercuryError.server(statusCode: 404, data: nil).description, "404 Not Found")
        XCTAssertEqual(MercuryError.server(statusCode: 409, data: nil).description, "409 Conflict")
        XCTAssertEqual(MercuryError.server(statusCode: 422, data: nil).description, "422 Unprocessable Entity")
        XCTAssertEqual(MercuryError.server(statusCode: 429, data: nil).description, "429 Too Many Requests")
        XCTAssertEqual(MercuryError.server(statusCode: 500, data: nil).description, "500 Internal Server Error")
        XCTAssertEqual(MercuryError.server(statusCode: 502, data: nil).description, "502 Bad Gateway")
        XCTAssertEqual(MercuryError.server(statusCode: 503, data: nil).description, "503 Service Unavailable")
        XCTAssertEqual(MercuryError.server(statusCode: 504, data: nil).description, "504 Gateway Timeout")
        // Unknown code (default branch)
        XCTAssertEqual(MercuryError.server(statusCode: 418, data: nil).description, "Server returned status code 418")
        // Unknown code, with non-empty UTF-8 data
        XCTAssertEqual(MercuryError.server(statusCode: 418, data: "I'm a teapot".data(using: .utf8)).description, "Server returned status code 418: I'm a teapot")
        // Data present but empty string
        XCTAssertEqual(MercuryError.server(statusCode: 400, data: "".data(using: .utf8)).description, "400 Bad Request")
        // Data present but not UTF-8 decodable
        let nonUtf8Data = Data([0xFF, 0xD8, 0xFF]) // Not valid UTF-8
        XCTAssertEqual(MercuryError.server(statusCode: 400, data: nonUtf8Data).description, "400 Bad Request")
        // Rest of the cases
        XCTAssertEqual(MercuryError.invalidResponse.description, "Invalid or unexpected response from server")
        XCTAssertEqual(MercuryError.transport(MockError()).description, "Transport error: Mock error")
        XCTAssertEqual(MercuryError.encoding(MockError()).description, "Encoding error: Mock error")
        XCTAssertEqual(
            MercuryError.decoding(namespace: "User", key: "name", underlyingError: MockError()).description,
            "Decoding failed in 'User' for key 'name': Mock error"
        )
    }
}
