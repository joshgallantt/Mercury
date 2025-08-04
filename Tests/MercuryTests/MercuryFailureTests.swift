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
    
    func test_givenInvalidURLError_whenInit_thenPropertiesAreSet() {
        // Given
        let error: MercuryError = .invalidURL
        let signature = "GET:/v1/resource"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertEqual(failure.requestSignature, signature)
        // CustomStringConvertible test
        XCTAssertEqual(error.description, "Invalid URL")
    }

    func test_givenServerErrorWithData_whenInit_thenDescriptionIncludesBody() {
        // Given
        let data = "Oops".data(using: .utf8)
        let error: MercuryError = .server(statusCode: 500, data: data)
        let signature = "POST:/v1/user"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertTrue(error.description.contains("Server returned status code 500 with body"))
        XCTAssertTrue(error.description.contains("Oops"))
        XCTAssertEqual(failure.requestSignature, signature)
    }

    func test_givenServerErrorWithoutData_whenInit_thenDescriptionOmitsBody() {
        // Given
        let error: MercuryError = .server(statusCode: 401, data: nil)
        let signature = "POST:/login"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertEqual(error.description, "Server returned status code 401")
        XCTAssertEqual(failure.requestSignature, signature)
    }

    func test_givenInvalidResponseError_whenInit_thenDescriptionIsCorrect() {
        // Given
        let error: MercuryError = .invalidResponse
        let signature = "PATCH:/foo"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertEqual(error.description, "Invalid or unexpected response from server")
        XCTAssertEqual(failure.requestSignature, signature)
    }

    func test_givenTransportError_whenInit_thenDescriptionContainsUnderlyingError() {
        // Given
        let underlying = DummyError(message: "Timeout")
        let error: MercuryError = .transport(underlying)
        let signature = "DELETE:/v2/item"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertTrue(error.description.contains("Transport error"))
        XCTAssertTrue(error.description.contains("Timeout"))
        XCTAssertEqual(failure.requestSignature, signature)
    }

    func test_givenEncodingError_whenInit_thenDescriptionContainsUnderlyingError() {
        // Given
        let underlying = DummyError(message: "Invalid JSON")
        let error: MercuryError = .encoding(underlying)
        let signature = "PUT:/users"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertTrue(error.description.contains("Encoding error"))
        XCTAssertTrue(error.description.contains("Invalid JSON"))
        XCTAssertEqual(failure.requestSignature, signature)
    }

    func test_givenDecodingFailedError_whenInit_thenDescriptionIsAccurate() {
        // Given
        let underlying = DummyError(message: "Missing key 'id'")
        let error: MercuryError = .decodingFailed(namespace: "User", key: "id", underlyingError: underlying)
        let signature = "GET:/users/1"
        
        // When
        let failure = MercuryFailure(error: error, requestSignature: signature)
        
        // Then
        XCTAssertTrue(error.description.contains("Decoding failed in 'User' for key 'id'"))
        XCTAssertTrue(error.description.contains("Missing key 'id'"))
        XCTAssertEqual(failure.requestSignature, signature)
    }
}
