//
//  HTTPClient.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 14/07/2025.
//

import Foundation

/// An abstraction for performing HTTP requests asynchronously.
///
/// `HTTPClient` enables decoupling of networking logic from consumers (such as repositories),
/// allowing for easy mocking in unit tests and interchangeable implementations. All methods are asynchronous
/// and safe for use with Swift Concurrency. Implementations must conform to `Sendable` for concurrency safety.
public protocol HTTPClient: Sendable {
    
    /// Performs an HTTP GET request to the specified path.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching policy for this request. If `nil`, implementation may use a default.
    /// - Returns: A result containing either a successful HTTP response or a failure with error details.
    func get(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<HTTPSuccess, HTTPFailure>
    
    /// Performs an HTTP POST request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - data: Optional raw data to send in the request body.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching policy for this request. If `nil`, implementation may use a default.
    /// - Returns: A result containing either a successful HTTP response or a failure with error details.
    func post(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        data: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<HTTPSuccess, HTTPFailure>
    
    /// Performs an HTTP POST request by encoding an `Encodable` body as JSON.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: An `Encodable` object to be JSON-encoded for the request body.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching policy for this request. If `nil`, implementation may use a default.
    ///   - encoder: The `JSONEncoder` to use for encoding the body. Defaults to a new `JSONEncoder`.
    /// - Returns: A result containing either a successful HTTP response or a failure with error details.
    func post<T: Encodable>(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: T,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        encoder: JSONEncoder
    ) async -> Result<HTTPSuccess, HTTPFailure>
    
    /// Performs an HTTP PUT request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: Optional raw data to send in the request body.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching policy for this request. If `nil`, implementation may use a default.
    /// - Returns: A result containing either a successful HTTP response or a failure with error details.
    func put(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<HTTPSuccess, HTTPFailure>
    
    /// Performs an HTTP PATCH request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: Optional raw data to send in the request body.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching policy for this request. If `nil`, implementation may use a default.
    /// - Returns: A result containing either a successful HTTP response or a failure with error details.
    func patch(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<HTTPSuccess, HTTPFailure>
    
    /// Performs an HTTP DELETE request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: Optional raw data to send in the request body.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching policy for this request. If `nil`, implementation may use a default.
    /// - Returns: A result containing either a successful HTTP response or a failure with error details.
    func delete(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<HTTPSuccess, HTTPFailure>
}
