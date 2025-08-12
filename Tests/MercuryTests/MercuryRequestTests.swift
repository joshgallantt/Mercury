//
//  MercuryRequestTests.swift
//  Mercury
//
//  Created by Josh Gallant on 12/08/2025.
//

import XCTest
@testable import Mercury
import CryptoKit

final class MercuryRequestTests: XCTestCase {
    struct TestBody: Encodable, Equatable {
        let foo: String
    }
    
    func test_canonicalString_basic_noOptionals() {
        let req = MercuryRequest(
            method: .GET,
            scheme: "https",
            host: "example.com",
            port: nil,
            path: "/api",
            headers: [:],
            query: nil,
            fragment: nil,
            body: nil,
            cachePolicy: .useProtocolCachePolicy
        )
        XCTAssertEqual(req.string, "GET|https://example.com/api")
    }
    
    func test_canonicalString_withPort() {
        let req = MercuryRequest(
            method: .POST,
            scheme: "http",
            host: "example.com",
            port: 8080,
            path: "/api",
            headers: [:],
            query: nil,
            fragment: nil,
            body: nil,
            cachePolicy: .reloadIgnoringCacheData
        )
        XCTAssertEqual(req.string, "POST|http://example.com:8080/api")
    }
    
    func test_canonicalString_withQuery_andSorting() {
        let req = MercuryRequest(
            method: .PUT,
            scheme: "https",
            host: "example.com",
            port: nil,
            path: "/api",
            headers: [:],
            query: ["b": "2", "a": "1"],
            fragment: nil,
            body: nil,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        // Query should be sorted as a=1&b=2
        XCTAssertEqual(req.string, "PUT|https://example.com/api?a=1&b=2")
    }
    
    func test_canonicalString_withFragment() {
        let req = MercuryRequest(
            method: .PATCH,
            scheme: "https",
            host: "example.com",
            port: 9000,
            path: "/v1",
            headers: [:],
            query: nil,
            fragment: "frag",
            body: nil,
            cachePolicy: .useProtocolCachePolicy
        )
        XCTAssertEqual(req.string, "PATCH|https://example.com:9000/v1#frag")
    }
    
    func test_canonicalString_withHeaders_sortedAndLowercased() {
        let req = MercuryRequest(
            method: .DELETE,
            scheme: "http",
            host: "api.com",
            port: nil,
            path: "/res",
            headers: ["X-Z": "z", "a": "a", "B": "2"],
            query: nil,
            fragment: nil,
            body: nil,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        // Headers sorted by lowercased key: a, b, x-z
        XCTAssertEqual(req.string, "DELETE|http://api.com/res|headers:a:a&b:2&x-z:z")
    }
    
    func test_canonicalString_allOptionals() {
        let req = MercuryRequest(
            method: .POST,
            scheme: "https",
            host: "host",
            port: 1234,
            path: "/p",
            headers: ["b": "B", "A": "A"],
            query: ["q": "1", "a": "A"],
            fragment: "frag",
            body: nil,
            cachePolicy: .useProtocolCachePolicy
        )
        // query: a=A&q=1; headers: a:A&b:B
        XCTAssertEqual(req.string, "POST|https://host:1234/p?a=A&q=1#frag|headers:a:A&b:B")
    }
    
    func test_canonicalString_emptyHeadersAndQuery() {
        let req = MercuryRequest(
            method: .GET,
            scheme: "https",
            host: "h",
            port: nil,
            path: "/",
            headers: [:],
            query: [:],
            fragment: nil,
            body: nil,
            cachePolicy: .useProtocolCachePolicy
        )
        // Query empty, so not included.
        XCTAssertEqual(req.string, "GET|https://h/")
    }
    
    func test_allHTTPMethods() {
        let all: [MercuryMethod] = [.GET, .POST, .PUT, .PATCH, .DELETE]
        for method in all {
            let req = MercuryRequest(
                method: method,
                scheme: "https",
                host: "e.com",
                port: nil,
                path: "/x",
                headers: [:],
                query: nil,
                fragment: nil,
                body: nil,
                cachePolicy: .useProtocolCachePolicy
            )
            XCTAssertTrue(req.string.hasPrefix(method.rawValue + "|"), "Prefix failed for \(method.rawValue)")
        }
    }
    
    func test_hash_isSHA256OfString() {
        let req = MercuryRequest(
            method: .GET,
            scheme: "https",
            host: "host",
            port: nil,
            path: "/",
            headers: ["A": "b"],
            query: nil,
            fragment: nil,
            body: nil,
            cachePolicy: .useProtocolCachePolicy
        )
        let expectedHash = {
            let data = Data(req.string.utf8)
            return data.withUnsafeBytes { _ in 
                Data(SHA256.hash(data: data)).map { String(format: "%02x", $0) }.joined()
            }
        }()
        XCTAssertEqual(req.hash, expectedHash)
    }
    
    func test_initializer_populatesAllProperties() {
        let body = TestBody(foo: "bar")
        let headers = ["Content-Type": "application/json"]
        let query = ["id": "123"]
        let req = MercuryRequest(
            method: .POST,
            scheme: "https",
            host: "api.site",
            port: 9000,
            path: "/submit",
            headers: headers,
            query: query,
            fragment: "frag",
            body: body,
            cachePolicy: .reloadIgnoringCacheData
        )
        XCTAssertEqual(req.method, .POST)
        XCTAssertEqual(req.scheme, "https")
        XCTAssertEqual(req.host, "api.site")
        XCTAssertEqual(req.port, 9000)
        XCTAssertEqual(req.path, "/submit")
        XCTAssertEqual(req.headers, headers)
        XCTAssertEqual(req.query, query)
        XCTAssertEqual(req.fragment, "frag")
        XCTAssertNotNil(req.body)
        XCTAssertEqual(req.cachePolicy, .reloadIgnoringCacheData)
        // Canonical string spot check
        XCTAssertTrue(req.string.contains("POST|https://api.site:9000/submit"))
    }
}
