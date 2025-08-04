//
//  URLComponentsParserTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class URLComponentsParserTests: XCTestCase {
    
    // MARK: - Basic Scheme Tests
    
    func test_givenHttpUrl_whenParse_thenExtractsHttpScheme() {
        // Given
        let input = "http://example.com"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "http")
        XCTAssertEqual(components.host, "example.com")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "")
    }
    
    func test_givenNoScheme_whenParse_thenDefaultsToHttps() {
        // Given
        let input = "example.com/foo"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.com")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "/foo")
    }
    
    func test_givenCustomScheme_whenParse_thenExtractsCustomScheme() {
        // Given
        let input = "foo+bar://host.com/path"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "foo+bar")
        XCTAssertEqual(components.host, "host.com")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "/path")
    }
    
    // MARK: - Host & Port Tests
    
    func test_givenHostWithPort_whenParse_thenExtractsPort() {
        // Given
        let input = "https://example.com:8080/path"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.com")
        XCTAssertEqual(components.port, 8080)
        XCTAssertEqual(components.basePath, "/path")
    }
    
    func test_givenHostWithInvalidPort_whenParse_thenPortIsNil() {
        // Given
        let input = "http://example.com:notaport/foo"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "http")
        XCTAssertEqual(components.host, "example.com:notaport")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "/foo")
    }
    
    func test_givenIpv6Host_whenParse_thenExtractsHost() {
        // Given
        let input = "https://[2001:db8::1]/resource"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "[2001:db8::1]")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "/resource")
    }
    
    func test_givenIpv6HostWithPort_whenParse_thenExtractsHostAndPort() {
        // Given
        let input = "http://[2001:db8::1]:9090/resource"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "http")
        XCTAssertEqual(components.host, "[2001:db8::1]")
        XCTAssertEqual(components.port, 9090)
        XCTAssertEqual(components.basePath, "/resource")
    }
    
    func test_givenHostWithNoPath_whenParse_thenBasePathIsEmpty() {
        // Given
        let input = "https://example.com"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.basePath, "")
    }
    
    func test_givenHostWithRootPath_whenParse_thenBasePathIsSlash() {
        // Given
        let input = "https://example.com/"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.basePath, "")
    }
    
    // MARK: - Path Normalization Tests
    
    func test_givenPathWithMultipleSlashes_whenParse_thenNormalizesBasePath() {
        // Given
        let input = "http://host.com//foo///bar/"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.basePath, "/foo/bar")
    }
    
    func test_givenPathWithLeadingTrailingSlashes_whenParse_thenNormalizesBasePath() {
        // Given
        let input = "host.com///path/to///resource//"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.basePath, "/path/to/resource")
    }
    
    func test_givenPathOnly_whenParse_thenExtractsBasePath() {
        // Given
        let input = "/my/path"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "/my/path")
    }
    
    func test_givenEmptyString_whenParse_thenAllAreDefaults() {
        // Given
        let input = ""
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "")
    }
    
    func test_givenWhitespaceString_whenParse_thenTrimsAndDefaults() {
        // Given
        let input = "    "
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "")
    }
    
    func test_givenPathWithNoHostOrScheme_whenParse_thenBasePathIsNormalized() {
        // Given
        let input = "////foo/bar///baz//"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "")
        XCTAssertNil(components.port)
        XCTAssertEqual(components.basePath, "/foo/bar/baz")
    }
    
    func test_givenHostWithPortAndNoPath_whenParse_thenBasePathIsEmpty() {
        // Given
        let input = "example.com:1234"
        
        // When
        let components = URLComponentsParser.parse(input)
        
        // Then
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.com")
        XCTAssertEqual(components.port, 1234)
        XCTAssertEqual(components.basePath, "")
    }
}
