//
//  BuildURLTests.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//

import XCTest

@testable import Mercury

final class BuildURLTests: XCTestCase {
    
    func test_givenAllFields_whenExecute_thenBuildsFullURL() {
        // Given
        let scheme = "https"
        let host = "example.com"
        let port = 8443
        let basePath = "/api/v1"
        let path = "/resource"
        let queryItems = ["foo": "bar", "baz": "42"]
        let fragment = "section1"
        
        // When
        let url = BuildURL.execute(
            scheme: scheme,
            host: host,
            port: port,
            basePath: basePath,
            path: path,
            queryItems: queryItems,
            fragment: fragment
        )
        
        // Then
        XCTAssertNotNil(url)
        let urlString = url!.absoluteString
        // Query order is not guaranteed, so check both
        let expected1 = "https://example.com:8443/api/v1/resource?foo=bar&baz=42#section1"
        let expected2 = "https://example.com:8443/api/v1/resource?baz=42&foo=bar#section1"
        XCTAssertTrue(urlString == expected1 || urlString == expected2)
    }
    
    func test_givenNilPort_whenExecute_thenBuildsURLWithoutPort() {
        // Given
        let url = BuildURL.execute(
            scheme: "http",
            host: "host.com",
            port: nil,
            basePath: "/base",
            path: "item"
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "http://host.com/base/item")
    }
    
    func test_givenEmptyBasePathAndPath_whenExecute_thenURLPathIsRoot() {
        // Given
        let url = BuildURL.execute(
            scheme: "http",
            host: "host.com",
            port: nil,
            basePath: "",
            path: ""
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "http://host.com/")
    }
    
    func test_givenNilQueryItemsAndFragment_whenExecute_thenURLHasNoQueryOrFragment() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "host.com",
            port: nil,
            basePath: "/api",
            path: "/test"
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "https://host.com/api/test")
    }
    
    func test_givenFragmentOnly_whenExecute_thenURLHasFragment() {
        // Given
        let url = BuildURL.execute(
            scheme: "http",
            host: "host.com",
            port: nil,
            basePath: "",
            path: "page",
            fragment: "anchor"
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "http://host.com/page#anchor")
    }
    
    func test_givenBasePathAndPathWithExtraSlashes_whenExecute_thenURLPathIsNormalized() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "host.com",
            port: nil,
            basePath: "//foo///bar//",
            path: "//baz/"
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "https://host.com/foo/bar/baz")
    }
    
    func test_givenEmptyBasePath_whenNormalizePath_thenReturnsNormalizedPath() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "host.com",
            port: nil,
            basePath: "",
            path: "bar"
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.path, "/bar")
    }
    
    func test_givenEmptyPath_whenNormalizePath_thenReturnsNormalizedPath() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "host.com",
            port: nil,
            basePath: "foo",
            path: ""
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.path, "/foo")
    }
    
    func test_givenBasePathAndPathWithSpaces_whenExecute_thenSpacesAreTrimmed() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "host.com",
            port: nil,
            basePath: " foo/ ",
            path: " /bar "
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "https://host.com/foo/bar")
    }
    
    func test_givenIPv6Host_whenExecute_thenURLIsValid() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "[::1]",
            port: 443,
            basePath: "api",
            path: "resource"
        )
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "https://[::1]:443/api/resource")
    }
    
    func test_givenNilHost_whenExecute_thenURLIsNil() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "",
            port: nil,
            basePath: "foo",
            path: "bar"
        )
        // Then
        XCTAssertNil(url)
    }
    
    func test_givenQueryItems_whenExecute_thenURLContainsAllQueryItems() {
        // Given
        let url = BuildURL.execute(
            scheme: "https",
            host: "host.com",
            port: nil,
            basePath: "",
            path: "endpoint",
            queryItems: ["foo": "", "bar": "baz"]
        )
        // Then
        XCTAssertNotNil(url)
        let urlString = url!.absoluteString
        // Order is not guaranteed
        let expected1 = "https://host.com/endpoint?foo=&bar=baz"
        let expected2 = "https://host.com/endpoint?bar=baz&foo="
        XCTAssertTrue(urlString == expected1 || urlString == expected2)
    }
}
