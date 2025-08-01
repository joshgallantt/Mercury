//
//  MercuryProtocol.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//

import Foundation

/// An abstraction for performing HTTP requests asynchronously.
///
/// `MercuryProtocol` enables decoupling of networking logic from consumers (such as repositories),
/// allowing for easy mocking in unit tests and interchangeable implementations. All methods are asynchronous
/// and safe for use with Swift Concurrency. Implementations must conform to `Sendable` for concurrency safety.
public protocol MercuryProtocol {

    /// Performs an HTTP GET request to the specified path.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - fragment: Optional URL fragment to append after the query string.
    ///   - cachePolicy: Optional caching policy. If `nil`, the default policy is applied.
    /// - Returns: A result containing either a `MercurySuccess` or a `MercuryFailure` (including the request signature).
    func get(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<MercurySuccess, MercuryFailure>

    /// Performs an HTTP POST request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - data: Optional raw `Data` payload to include in the request body.
    ///   - fragment: Optional URL fragment to append after the query string.
    ///   - cachePolicy: Optional caching policy. If `nil`, the default policy is applied.
    /// - Returns: A result containing either a `MercurySuccess` or a `MercuryFailure` (including the request signature).
    func post(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        data: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<MercurySuccess, MercuryFailure>

    /// Performs an HTTP POST request by encoding an `Encodable` object into JSON.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: An encodable object to be serialized as JSON in the request body.
    ///   - fragment: Optional URL fragment to append after the query string.
    ///   - cachePolicy: Optional caching policy. If `nil`, the default policy is applied.
    ///   - encoder: The `JSONEncoder` to use for encoding the object. Defaults to a new `JSONEncoder`.
    /// - Returns: A result containing either a `MercurySuccess` or a `MercuryFailure` (including the request signature).
    func post<T: Encodable>(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: T,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        encoder: JSONEncoder
    ) async -> Result<MercurySuccess, MercuryFailure>

    /// Performs an HTTP PUT request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: Optional raw `Data` payload to include in the request body.
    ///   - fragment: Optional URL fragment to append after the query string.
    ///   - cachePolicy: Optional caching policy. If `nil`, the default policy is applied.
    /// - Returns: A result containing either a `MercurySuccess` or a `MercuryFailure` (including the request signature).
    func put(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<MercurySuccess, MercuryFailure>

    /// Performs an HTTP PATCH request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: Optional raw `Data` payload to include in the request body.
    ///   - fragment: Optional URL fragment to append after the query string.
    ///   - cachePolicy: Optional caching policy. If `nil`, the default policy is applied.
    /// - Returns: A result containing either a `MercurySuccess` or a `MercuryFailure` (including the request signature).
    func patch(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<MercurySuccess, MercuryFailure>

    /// Performs an HTTP DELETE request to the specified path, with optional raw body data.
    ///
    /// - Parameters:
    ///   - path: The path component to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - queryItems: Optional key-value pairs for the query string.
    ///   - body: Optional raw `Data` payload to include in the request body.
    ///   - fragment: Optional URL fragment to append after the query string.
    ///   - cachePolicy: Optional caching policy. If `nil`, the default policy is applied.
    /// - Returns: A result containing either a `MercurySuccess` or a `MercuryFailure` (including the request signature).
    func delete(
        _ path: String,
        headers: [String: String]?,
        queryItems: [String: String]?,
        body: Data?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?
    ) async -> Result<MercurySuccess, MercuryFailure>
}
