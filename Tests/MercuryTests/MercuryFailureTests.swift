//
//  MercuryFailureTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class MercuryFailureTests: XCTestCase {
    struct DummyError: Error, LocalizedError, Equatable {
        let message: String
        var errorDescription: String? { message }
        static func == (lhs: DummyError, rhs: DummyError) -> Bool {
            lhs.message == rhs.message
        }
    }

    func test_givenInvalidURLError_whenInit_thenPropertiesAndDescriptionMatch() {
        // Given
        let requestString = "GET:/v1/resource"
        // SHA256("GET:/v1/resource")
        let expectedSignature = "a8d5348e99a2243ea788a0238e7a82c70b1aa37bb2fa65d44479eaa18687723b"
        let error: MercuryError = .invalidURL

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(error.description, "Invalid URL")
        XCTAssertEqual(failure.description, error.description)
    }

    func test_givenServerErrorWithData_whenInit_thenDescriptionIncludesBody() {
        // Given
        let requestString = "POST:/v1/user"
        // SHA256("POST:/v1/user")
        let expectedSignature = "457492c9cc57ad8c13f8d6b08f80cea7e89fc0f826f70add69fb1f10c16100b6"
        let data = "Oops".data(using: .utf8)
        let error: MercuryError = .server(statusCode: 500, data: data)

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertEqual(error.description, "500 Internal Server Error: Oops")
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(failure.description, error.description)
    }

    func test_givenServerErrorWithoutData_whenInit_thenDescriptionOmitsBody() {
        // Given
        let requestString = "POST:/login"
        // SHA256("POST:/login")
        let expectedSignature = "0fa1628f847f67036f3a1e0247e6bc4df0d1dfc3815e88326884537a8fb12dc1"
        let error: MercuryError = .server(statusCode: 401, data: nil)

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertEqual(error.description, "401 Unauthorized")
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(failure.description, error.description)
    }

    func test_givenInvalidResponseError_whenInit_thenDescriptionIsCorrect() {
        // Given
        let requestString = "PATCH:/foo"
        // SHA256("PATCH:/foo")
        let expectedSignature = "e6c20ea3cacea0280f88ef798f5437a5f6ee33044a18f7349eb0380afb868f20"
        let error: MercuryError = .invalidResponse

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertEqual(error.description, "Invalid or unexpected response from server")
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(failure.description, error.description)
    }

    func test_givenTransportError_whenInit_thenDescriptionContainsUnderlyingError() {
        // Given
        let requestString = "DELETE:/v2/item"
        // SHA256("DELETE:/v2/item")
        let expectedSignature = "d2f8ce8d36d61c9b528ff94181c9d77e620ea4ba516b2efa9e64bd075dc7ba53"
        let underlying = DummyError(message: "Timeout")
        let error: MercuryError = .transport(underlying)

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertTrue(error.description.contains("Transport error"))
        XCTAssertTrue(error.description.contains("Timeout"))
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(failure.description, error.description)
    }

    func test_givenEncodingError_whenInit_thenDescriptionContainsUnderlyingError() {
        // Given
        let requestString = "PUT:/users"
        // SHA256("PUT:/users")
        let expectedSignature = "778cb84b178eefab9e3969d8247d2d301c4495618612d6de901aeeb5630812c4"
        let underlying = DummyError(message: "Invalid JSON")
        let error: MercuryError = .encoding(underlying)

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertTrue(error.description.contains("Encoding error"))
        XCTAssertTrue(error.description.contains("Invalid JSON"))
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(failure.description, error.description)
    }

    func test_givenDecodingFailedError_whenInit_thenDescriptionIsAccurate() {
        // Given
        let requestString = "GET:/users/1"
        // SHA256("GET:/users/1")
        let expectedSignature = "4c07db0fc628c9b2482f042803dc5b00212e4f183682587b19b4d81f6bfce768"
        let underlying = DummyError(message: "Missing key 'id'")
        let error: MercuryError = .decoding(namespace: "User", key: "id", underlyingError: underlying)

        // When
        let failure = MercuryFailure(error: error, requestString: requestString)

        // Then
        XCTAssertTrue(error.description.contains("Decoding failed in 'User' for key 'id'"))
        XCTAssertTrue(error.description.contains("Missing key 'id'"))
        XCTAssertEqual(failure.requestString, requestString)
        XCTAssertEqual(failure.requestSignature, expectedSignature)
        XCTAssertEqual(failure.description, error.description)
    }
}
