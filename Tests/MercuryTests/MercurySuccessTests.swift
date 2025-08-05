//
//  MercurySuccessTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class MercurySuccessTests: XCTestCase {
    struct DummyDecodable: Decodable, Equatable {
        let id: Int
        let name: String
    }
    
    func test_givenAllParameters_whenInit_thenAllPropertiesAreSet() {
        // Given
        let dummyValue = DummyDecodable(id: 42, name: "Test User")
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        let canonicalRequestString = "GET|https://example.com|headers:content-type:application/json"
        let expectedSignature = "9ad8ee00464c4c11f514a657e92a9ad66381bbeac1ea2098b7edd87800d6981d"

        // When
        let success = MercurySuccess(
            value: dummyValue,
            httpResponse: response,
            requestString: canonicalRequestString
        )

        // Then
        XCTAssertEqual(success.value, dummyValue)
        XCTAssertEqual(success.httpResponse.statusCode, 200)
        XCTAssertEqual(success.httpResponse.url, url)
        XCTAssertEqual(success.requestString, canonicalRequestString)
        XCTAssertEqual(success.requestSignature, expectedSignature)
    }
    
    func test_givenDifferentValues_whenInit_thenDistinctInstances() {
        // Given
        let dummyA = DummyDecodable(id: 1, name: "A")
        let dummyB = DummyDecodable(id: 2, name: "B")
        let urlA = URL(string: "https://a.com")!
        let urlB = URL(string: "https://b.com")!
        let responseA = HTTPURLResponse(url: urlA, statusCode: 201, httpVersion: nil, headerFields: nil)!
        let responseB = HTTPURLResponse(url: urlB, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let sigA = "sigA"
        let sigB = "sigB"
        
        // When
        let successA = MercurySuccess(value: dummyA, httpResponse: responseA, requestString: sigA)
        let successB = MercurySuccess(value: dummyB, httpResponse: responseB, requestString: sigB)
        
        // Then
        XCTAssertNotEqual(successA.value, successB.value)
        XCTAssertNotEqual(successA.httpResponse, successB.httpResponse)
        XCTAssertNotEqual(successA.requestSignature, successB.requestSignature)
    }
    
    func test_givenDecodableType_whenInit_thenTypeIsCorrect() {
        // Given
        let value = 123
        let url = URL(string: "https://swift.org")!
        let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!
        let signature = "int-sig"
        
        // When
        let success = MercurySuccess(value: value, httpResponse: response, requestString: signature)
        
        // Then
        XCTAssertEqual(success.value, 123)
        XCTAssertTrue(type(of: success.value) == Int.self)
    }
    
    func test_givenEmptyRequestString_whenInit_thenRequestSignatureIsEmpty() {
        // Given
        let dummyValue = DummyDecodable(id: 1, name: "A")
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let emptyRequestString = ""

        // When
        let success = MercurySuccess(
            value: dummyValue,
            httpResponse: response,
            requestString: emptyRequestString
        )

        // Then
        XCTAssertEqual(success.requestString, "")
        XCTAssertEqual(success.requestSignature, "")
    }

}
