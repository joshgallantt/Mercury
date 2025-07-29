//
//  RequestSignatureTests.swift
//  Mercury
//
//  Created by Josh Gallant on 29/07/2025.
//


import XCTest
import Foundation
@testable import Mercury

final class RequestSignatureTests: XCTestCase {

    func test_givenSameURLAndMethod_whenGenerate_thenSignatureIsEqual() {
        // Given
        let url = URL(string: "https://example.com/api?b=2&a=1#frag")!
        var request1 = URLRequest(url: url)
        request1.httpMethod = "GET"
        
        var request2 = URLRequest(url: url)
        request2.httpMethod = "GET"

        // When
        let sig1 = RequestSignature.generate(for: request1)
        let sig2 = RequestSignature.generate(for: request2)

        // Then
        XCTAssertEqual(sig1, sig2)
    }

    func test_givenSameURLDifferentMethod_whenGenerate_thenSignatureDiffers() {
        // Given
        let url = URL(string: "https://example.com/data")!
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        
        var postRequest = URLRequest(url: url)
        postRequest.httpMethod = "POST"

        // When
        let getSig = RequestSignature.generate(for: getRequest)
        let postSig = RequestSignature.generate(for: postRequest)

        // Then
        XCTAssertNotEqual(getSig, postSig)
    }

    func test_givenSameBody_whenGenerate_thenBodyHashIsIncludedAndStable() {
        // Given
        let url = URL(string: "https://example.com/submit")!
        let body = #"{"name":"Josh"}"#.data(using: .utf8)!

        var req1 = URLRequest(url: url)
        req1.httpMethod = "POST"
        req1.httpBody = body

        var req2 = URLRequest(url: url)
        req2.httpMethod = "POST"
        req2.httpBody = body

        // When
        let sig1 = RequestSignature.generate(for: req1)
        let sig2 = RequestSignature.generate(for: req2)

        // Then
        XCTAssertEqual(sig1, sig2)
        XCTAssertTrue(sig1.contains("body:"), "Expected body hash to be included in signature")
    }

    func test_givenDifferentBodies_whenGenerate_thenSignatureDiffers() {
        // Given
        let url = URL(string: "https://example.com/submit")!

        var req1 = URLRequest(url: url)
        req1.httpMethod = "POST"
        req1.httpBody = #"{"name":"A"}"#.data(using: .utf8)

        var req2 = URLRequest(url: url)
        req2.httpMethod = "POST"
        req2.httpBody = #"{"name":"B"}"#.data(using: .utf8)

        // When
        let sig1 = RequestSignature.generate(for: req1)
        let sig2 = RequestSignature.generate(for: req2)

        // Then
        XCTAssertNotEqual(sig1, sig2)
    }

    func test_givenSameHeadersDifferentOrder_whenGenerate_thenSignatureIsEqual() {
        // Given
        let url = URL(string: "https://example.com/")!

        var req1 = URLRequest(url: url)
        req1.httpMethod = "GET"
        req1.allHTTPHeaderFields = [
            "Authorization": "Bearer xyz",
            "Accept": "application/json"
        ]

        var req2 = URLRequest(url: url)
        req2.httpMethod = "GET"
        req2.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Authorization": "Bearer xyz"
        ]

        // When
        let sig1 = RequestSignature.generate(for: req1)
        let sig2 = RequestSignature.generate(for: req2)

        // Then
        XCTAssertEqual(sig1, sig2, "Expected headers to be order-independent")
    }

    func test_givenDifferentHeaders_whenGenerate_thenSignatureDiffers() {
        // Given
        let url = URL(string: "https://example.com")!

        var req1 = URLRequest(url: url)
        req1.httpMethod = "GET"
        req1.allHTTPHeaderFields = ["X-Custom": "123"]

        var req2 = URLRequest(url: url)
        req2.httpMethod = "GET"
        req2.allHTTPHeaderFields = ["X-Custom": "456"]

        // When
        let sig1 = RequestSignature.generate(for: req1)
        let sig2 = RequestSignature.generate(for: req2)

        // Then
        XCTAssertNotEqual(sig1, sig2)
    }

    func test_givenHeaderKeysWithDifferentCasing_whenGenerate_thenTreatedCaseInsensitive() {
        // Given
        let url = URL(string: "https://example.com")!

        var req1 = URLRequest(url: url)
        req1.httpMethod = "GET"
        req1.allHTTPHeaderFields = ["ACCEPT": "application/json"]

        var req2 = URLRequest(url: url)
        req2.httpMethod = "GET"
        req2.allHTTPHeaderFields = ["accept": "application/json"]

        // When
        let sig1 = RequestSignature.generate(for: req1)
        let sig2 = RequestSignature.generate(for: req2)

        // Then
        XCTAssertEqual(sig1, sig2, "Expected header keys to be treated case-insensitively")
    }
    
    func test_givenSameRequestBuiltMultipleTimes_whenGenerate_thenSignaturesAreIdentical() {
        // Given
        let url = URL(string: "https://api.example.com/v1/search?q=swift#results")!
        let body = #"{"search":"swift"}"#.data(using: .utf8)!
        let headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        func makeRequest() -> URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            request.allHTTPHeaderFields = headers
            return request
        }

        // When
        let signatures = (0..<5).map { _ in
            let request = makeRequest()
            return RequestSignature.generate(for: request)
        }

        // Then
        let first = signatures.first!
        for sig in signatures {
            XCTAssertEqual(sig, first, "Expected all signatures to match, but got a mismatch.")
        }
    }

}
