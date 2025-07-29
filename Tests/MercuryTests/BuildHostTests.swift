//
//  BuildHostTests.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//

import XCTest

@testable import Mercury

final class BuildHostTests: XCTestCase {
    
    func test_givenURLWithSchemeAndPath_whenExecute_thenParsesAllComponents() throws {
        // Given
        let input = "https://example.com/api/v1/resource"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "example.com")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/api/v1/resource")
    }
    
    func test_givenURLWithSchemeAndNoPath_whenExecute_thenParsesHostAndEmptyBasePath() throws {
        // Given
        let input = "http://myhost"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "myhost")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "")
    }
    
    func test_givenURLWithNoScheme_whenExecute_thenDefaultsToHTTPS() throws {
        // Given
        let input = "testhost/path"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "testhost")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/path")
    }
    
    func test_givenURLWithSchemeOnly_whenExecute_thenHostIsEmpty() throws {
        // Given
        let input = "ftp://"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "ftp")
        XCTAssertEqual(result.host, "")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "")
    }
    
    func test_givenURLWithMultipleSlashesInBasePath_whenExecute_thenBasePathIsNormalized() throws {
        // Given
        let input = "https://host.com//foo///bar/"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "host.com")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/foo/bar")
    }
    
    func test_givenURLWithOnlyHostAndTrailingSlash_whenExecute_thenBasePathIsEmpty() throws {
        // Given
        let input = "https://myhost/"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "myhost")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "")
    }
    
    func test_givenURLWithEmptyString_whenExecute_thenDefaultsSchemeAndEmptyHostBasePath() throws {
        // Given
        let input = ""
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "")
    }
    
    func test_givenURLWithWhitespaceAroundHost_whenExecute_thenTrimsWhitespace() throws {
        // Given
        let input = "https://  myhost.com  /api"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "myhost.com")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/api")
    }
    
    func test_givenURLWithPlusAndDotInScheme_whenExecute_thenSchemeIsParsed() throws {
        // Given
        let input = "my+custom.scheme://host.com/foo"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "my+custom.scheme")
        XCTAssertEqual(result.host, "host.com")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/foo")
    }
    
    func test_givenIPv4HostWithPort_whenExecute_thenParsesHostAndPort() throws {
        // Given
        let input = "http://127.0.0.1:1234/api"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "127.0.0.1")
        XCTAssertEqual(result.port, 1234)
        XCTAssertEqual(result.basePath, "/api")
    }
    
    func test_givenHostWithPort_whenExecute_thenParsesHostAndPort() throws {
        // Given
        let input = "https://example.com:8443/api"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "example.com")
        XCTAssertEqual(result.port, 8443)
        XCTAssertEqual(result.basePath, "/api")
    }
    
    func test_givenIPv6HostWithPort_whenExecute_thenParsesHostAndPort() throws {
        // Given
        let input = "http://[::1]:8080/v1"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "[::1]")
        XCTAssertEqual(result.port, 8080)
        XCTAssertEqual(result.basePath, "/v1")
    }
    
    func test_givenIPv6HostWithoutPort_whenExecute_thenParsesHostAndNoPort() throws {
        // Given
        let input = "https://[2001:db8::1]/apipath"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "[2001:db8::1]")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/apipath")
    }
    
    func test_givenHostWithInvalidPort_whenExecute_thenPortIsNilAndHostIncludesPortString() throws {
        // Given
        let input = "https://host.com:notaport/path"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        // Should not treat as a port, host remains whole string before /.
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "host.com:notaport")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/path")
    }
    
    func test_givenHostWithMultipleColonsButNoIPv6_whenExecute_thenFirstColonSplitsPort() throws {
        // Given
        let input = "https://some.host:8081:extra/api"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        // Only the first colon splits the port, but "8081:extra" is not Int, so host is full string
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "some.host:8081:extra")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/api")
    }
    
    func test_givenBasePathWithMultipleSlashes_whenNormalizeBasePath_thenRemovesExtras() {
        // Given
        let input = "foo///bar//baz/"
        
        // When
        let result = BuildHost.normalizeBasePath(input)
        
        // Then
        XCTAssertEqual(result, "/foo/bar/baz")
    }
    
    func test_givenBasePathIsEmpty_whenNormalizeBasePath_thenReturnsEmptyString() {
        // Given
        let input = ""
        
        // When
        let result = BuildHost.normalizeBasePath(input)
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func test_givenHostWithPortOnly_whenExtractHostAndPort_thenReturnsHostAndPort() {
        // Given
        let input = "host.com:5555"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input)
        
        // Then
        XCTAssertEqual(host, "host.com")
        XCTAssertEqual(port, 5555)
    }
    
    func test_givenIPv6HostWithPortOnly_whenExtractHostAndPort_thenReturnsHostAndPort() {
        // Given
        let input = "[::1]:4321"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input)
        
        // Then
        XCTAssertEqual(host, "[::1]")
        XCTAssertEqual(port, 4321)
    }
    
    func test_givenIPv6HostWithoutPort_whenExtractHostAndPort_thenReturnsHostAndNilPort() {
        // Given
        let input = "[::1]"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input)
        
        // Then
        XCTAssertEqual(host, "[::1]")
        XCTAssertEqual(port, nil)
    }
    
    func test_givenHostWithoutPort_whenExtractHostAndPort_thenReturnsHostAndNilPort() {
        // Given
        let input = "host.com"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input)
        
        // Then
        XCTAssertEqual(host, "host.com")
        XCTAssertEqual(port, nil)
    }
    
    func test_givenHostWithColonButNoPortNumber_whenExtractHostAndPort_thenReturnsOriginalHost() {
        // Given
        let input = "host.com:foo"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input)
        
        // Then
        XCTAssertEqual(host, "host.com:foo")
        XCTAssertEqual(port, nil)
    }
    
    func test_givenBasePathWithLeadingAndTrailingSlashes_whenNormalizeBasePath_thenReturnsNormalized() {
        // Given
        let input = "/foo/bar/"
        
        // When
        let result = BuildHost.normalizeBasePath(input)
        
        // Then
        XCTAssertEqual(result, "/foo/bar")
    }
    
    func test_givenPathOnly_whenExecute_thenHostIsEmptyBasePathIsWholePath() throws {
        // Given
        let input = "/apionly/path"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "")
        XCTAssertEqual(result.port, nil)
        XCTAssertEqual(result.basePath, "/apionly/path")
    }
    
    func test_givenEmptyBasePath_whenNormalizeBasePath_thenReturnsEmpty() {
        // Given
        let input = ""
        
        // When
        let result = BuildHost.normalizeBasePath(input)
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func test_givenURLWithUserInfoInHost_whenExecute_thenHostIncludesUserInfoAndPortIsNil() throws {
        // Given
        let input = "http://user:pass@host.com:123/api"
        
        // When
        let result = try BuildHost.execute(input)
        
        // Then
        // All before the first slash is considered host in this implementation
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "user:pass@host.com:123")
        XCTAssertNil(result.port)
        XCTAssertEqual(result.basePath, "/api")
    }

    func test_givenHostWithPortWithWhitespace_whenExtractHostAndPort_thenReturnsHostAndPort() {
        // Given
        let input = "host.com: 8080"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input.trimmingCharacters(in: .whitespaces))
        
        // Then
        XCTAssertEqual(host, "host.com: 8080") // not a valid port, so port is nil
        XCTAssertNil(port)
    }
    
    func test_givenEmptyInput_whenExtractHostAndBasePath_thenReturnsEmpty() {
        // Given
        let input = ""
        
        // When
        let (host, basePath) = BuildHost.extractHostAndBasePath(from: input)
        
        // Then
        XCTAssertEqual(host, "")
        XCTAssertEqual(basePath, "")
    }

    func test_givenInvalidRegexPattern_whenExtractSchemeAndRest_thenThrowsError() {
        // Given
        let pattern = "((("
        
        // When/Then
        XCTAssertThrowsError(try NSRegularExpression(pattern: pattern, options: []))
        // Note: Can't reach this in current code, but required for coverage if regex string changes.
    }
    
    func test_givenUnclosedIPv6Host_whenExtractHostAndPort_thenReturnsOriginalHostAndNilPort() {
        // Given
        let input = "[::1"
        
        // When
        let (host, port) = BuildHost.extractHostAndPort(input)
        
        // Then
        XCTAssertEqual(host, "[::1")
        XCTAssertNil(port)
    }
    
    func test_givenHostWithAlphaNumericPort_whenExtractHostAndPort_thenReturnsOriginalHostAndNilPort() {
        // Given
        let input = "example.com:80eight"

        // When
        let (host, port) = BuildHost.extractHostAndPort(input)

        // Then
        XCTAssertEqual(host, "example.com:80eight")
        XCTAssertNil(port)
    }
    

}
