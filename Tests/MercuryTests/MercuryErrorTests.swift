//
//  MercuryErrorTests.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//
import XCTest

@testable import Mercury

final class MercuryErrorTests: XCTestCase {
    
    func test_givenInvalidURL_whenDescription_thenIsCorrect() {
        // Given
        let failure = MercuryError.invalidURL
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertEqual(description, "Invalid URL")
    }
    
    func test_givenServerErrorWithData_whenDescription_thenIncludesCodeAndBody() {
        // Given
        let message = "Error details from server"
        let data = message.data(using: .utf8)
        let failure = MercuryError.server(statusCode: 404, data: data)
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertTrue(description.contains("404"))
        XCTAssertTrue(description.contains("Server returned error status code: 404"))
        XCTAssertTrue(description.contains(message))
        XCTAssertTrue(description.contains("Server response body"))
    }
    
    func test_givenServerErrorWithEmptyData_whenDescription_thenNoBodyIncluded() {
        // Given
        let data = Data()
        let failure = MercuryError.server(statusCode: 500, data: data)
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertEqual(description, "Server returned error status code: 500")
    }
    
    func test_givenServerErrorWithNilData_whenDescription_thenNoBodyIncluded() {
        // Given
        let failure = MercuryError.server(statusCode: 403, data: nil)
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertEqual(description, "Server returned error status code: 403")
    }
    
    func test_givenInvalidResponse_whenDescription_thenIsCorrect() {
        // Given
        let failure = MercuryError.invalidResponse
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertEqual(description, "Invalid or unexpected response from server")
    }
    
    func test_givenTransportError_whenDescription_thenIncludesErrorDescription() {
        // Given
        let error = NSError(domain: "Transport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        let failure = MercuryError.transport(error)
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertTrue(description.contains("Transport error"))
        XCTAssertTrue(description.contains("Connection lost"))
    }
    
    func test_givenEncodingError_whenDescription_thenIncludesErrorDescription() {
        // Given
        struct Dummy: Error, LocalizedError {
            var errorDescription: String? { "Failed to encode" }
        }
        let error = Dummy()
        let failure = MercuryError.encoding(error)
        
        // When
        let description = failure.description
        
        // Then
        XCTAssertTrue(description.contains("Encoding error"))
        XCTAssertTrue(description.contains("Failed to encode"))
    }
    
    func test_givenAllCases_whenConformsToError() {
        // Given
        let failures: [MercuryError] = [
            .invalidURL,
            .server(statusCode: 500, data: nil),
            .invalidResponse,
            .transport(NSError(domain: "", code: 0)),
            .encoding(NSError(domain: "", code: 0))
        ]
        
        // Then
        for failure in failures {
            let err: Error = failure
            XCTAssertNotNil(err)
        }
    }
}
