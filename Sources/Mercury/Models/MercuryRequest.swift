//
//  MercuryRequest.swift
//  Mercury
//
//  Created by Josh Gallant on 11/08/2025.
//


import Foundation
import CryptoKit

public struct MercuryRequest {
    public let method: MercuryMethod
    public let scheme: String
    public let host: String
    public let port: Int?
    public let path: String
    public let headers: [String: String]
    public let query: [String: String]?
    public let fragment: String?
    public let body: Data?
    public let cachePolicy: URLRequest.CachePolicy
    
    /// The canonical string representation of this request
    public let string: String
    
    /// The SHA256 hash of the canonical string (useful for caching)
    public var signature: String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Alias for signature
    public var hash: String {
        signature
    }
    
    public init(
        method: MercuryMethod,
        scheme: String,
        host: String,
        port: Int?,
        path: String,
        headers: [String: String],
        query: [String: String]?,
        fragment: String?,
        body: Data?,
        cachePolicy: URLRequest.CachePolicy
    ) {
        self.method = method
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.headers = headers
        self.query = query
        self.fragment = fragment
        self.body = body
        self.cachePolicy = cachePolicy
        
        // Generate canonical string
        self.string = MercuryRequest.generateCanonicalString(
            method: method,
            scheme: scheme,
            host: host,
            port: port,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            body: body
        )
    }
    
    private static func generateCanonicalString(
        method: MercuryMethod,
        scheme: String,
        host: String,
        port: Int?,
        path: String,
        headers: [String: String],
        query: [String: String]?,
        fragment: String?,
        body: Data?
    ) -> String {
        var components: [String] = []
        
        // Add method
        components.append(method.rawValue)
        
        // Build URL string representation
        var urlString = "\(scheme)://\(host)"
        if let port = port {
            urlString += ":\(port)"
        }
        urlString += path
        
        if let query = query, !query.isEmpty {
            let queryString = query
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            urlString += "?\(queryString)"
        }
        
        if let fragment = fragment {
            urlString += "#\(fragment)"
        }
        
        components.append(urlString)
        
        // Add headers if present
        if !headers.isEmpty {
            let canonicalHeaders = headers
                .sorted { $0.key.lowercased() < $1.key.lowercased() }
                .map { "\($0.key.lowercased()):\($0.value)" }
                .joined(separator: "&")
            components.append("headers:\(canonicalHeaders)")
        }
        
        return components.joined(separator: "|")
    }
}
