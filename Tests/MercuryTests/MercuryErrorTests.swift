//
//  MercuryErrorTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class MercuryErrorTests: XCTestCase {
    func test_givenInvalidURL_whenDescription_thenMatches() {
        // Given
        let error = MercuryError.invalidURL
        
        // When
        let description = error.description
        
        // Then
        XCTAssertEqual(description, "Invalid URL")
    }
    
    func test_givenServerWithBody_whenDescription_thenContainsStatusCodeAndBody() {
        // Given
        let bodyString = "Error occurred"
        let bodyData = bodyString.data(using: .utf8)
        let error = MercuryError.server(statusCode: 404, data: bodyData)
        
        // When
        let description = error.description
        
        // Then
        XCTAssertTrue(description.contains("404"))
        XCTAssertTrue(description.contains(bodyString))
        XCTAssertTrue(description.hasPrefix("Server returned status code 404"))
    }
    
    func test_givenServerWithEmptyBody_whenDescription_thenContainsStatusCodeOnly() {
        // Given
        let error = MercuryError.server(statusCode: 500, data: nil)
        
        // When
        let description = error.description
        
        // Then
        XCTAssertEqual(description, "Server returned status code 500")
    }
    
    func test_givenServerWithEmptyData_whenDescription_thenContainsStatusCodeOnly() {
        // Given
        let error = MercuryError.server(statusCode: 401, data: Data())
        
        // When
        let description = error.description
        
        // Then
        XCTAssertEqual(description, "Server returned status code 401")
    }
    
    func test_givenInvalidResponse_whenDescription_thenMatches() {
        // Given
        let error = MercuryError.invalidResponse
        
        // When
        let description = error.description
        
        // Then
        XCTAssertEqual(description, "Invalid or unexpected response from server")
    }
    
    func test_givenTransport_whenDescription_thenIncludesErrorLocalizedDescription() {
        // Given
        struct DummyError: LocalizedError { var errorDescription: String? { "Network failure" } }
        let underlyingError = DummyError()
        let error = MercuryError.transport(underlyingError)
        
        // When
        let description = error.description
        
        // Then
        XCTAssertTrue(description.contains("Transport error"))
        XCTAssertTrue(description.contains("Network failure"))
    }
    
    func test_givenEncoding_whenDescription_thenIncludesErrorLocalizedDescription() {
        // Given
        struct DummyError: LocalizedError { var errorDescription: String? { "Encoding failed" } }
        let underlyingError = DummyError()
        let error = MercuryError.encoding(underlyingError)
        
        // When
        let description = error.description
        
        // Then
        XCTAssertTrue(description.contains("Encoding error"))
        XCTAssertTrue(description.contains("Encoding failed"))
    }
    
    func test_givenDecodingFailed_whenDescription_thenIncludesNamespaceKeyAndError() {
        // Given
        struct DummyError: LocalizedError { var errorDescription: String? { "Missing value" } }
        let underlyingError = DummyError()
        let error = MercuryError.decodingFailed(namespace: "User", key: "id", underlyingError: underlyingError)
        
        // When
        let description = error.description
        
        // Then
        XCTAssertTrue(description.contains("Decoding failed in 'User' for key 'id'"))
        XCTAssertTrue(description.contains("Missing value"))
    }
}
