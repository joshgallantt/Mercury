//
//  URLComponentsParserTests.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury

final class URLComponentsParserTests: XCTestCase {
    
    func test_givenVariousURLs_whenParse_thenCorrectComponents() {
        // Given/When/Then
        let testCases: [(input: String, expected: (scheme: String, host: String, port: Int?, basePath: String))] = [
            ("http://example.com", ("http", "example.com", nil, "")),
            ("example.com/foo", ("https", "example.com", nil, "/foo")),
            ("https://example.com:8080/path", ("https", "example.com", 8080, "/path")),
            ("http://[2001:db8::1]:9090/resource", ("http", "[2001:db8::1]", 9090, "/resource")),
            ("/my/path", ("https", "", nil, "/my/path")),
            ("", ("https", "", nil, ""))
        ]
        
        for (input, expected) in testCases {
            let result = URLComponentsParser.parse(input)
            XCTAssertEqual(result.scheme, expected.scheme, "Failed for input: \(input)")
            XCTAssertEqual(result.host, expected.host, "Failed for input: \(input)")
            XCTAssertEqual(result.port, expected.port, "Failed for input: \(input)")
            XCTAssertEqual(result.basePath, expected.basePath, "Failed for input: \(input)")
        }
    }
    
    func test_givenIPv6WithoutPort_whenParse_thenHostIsIPv6PortIsNil() {
        // Given
        let input = "http://[2001:db8::2]/foo"
        
        // When
        let result = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "[2001:db8::2]")
        XCTAssertNil(result.port)
        XCTAssertEqual(result.basePath, "/foo")
    }

}
