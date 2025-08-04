//
//  MercuryProtocol.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//

import Foundation


/// `MercuryProtocol` exposes a clean, minimal interface for networking. Each method:
/// - Automatically encodes a request body (`Encodable`) if present
/// - Automatically decodes a response body (`Decodable`) into a concrete type
/// - Returns a `Result` containing either a successful response (`MercurySuccess<Response>`)
///   or a structured failure (`MercuryFailure`)
///
/// The response type must be passed explicitly using `responseType`, allowing full control
/// and avoiding ambiguity around Swift generic inference.
public protocol MercuryProtocol {

    /// Sends a `GET` request and decodes the response into the specified type.
    ///
    /// Use this for retrieving data without a request body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL (e.g., `"/search/multi"`).
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters (e.g., `["q": "inception"]`).
    ///   - fragment: Optional URL fragment (e.g., `#section`).
    ///   - cachePolicy: Optional caching behavior override. Defaults to the client’s default if `nil`.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func get<Response: Decodable>(
        path: String,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure>

    /// Sends a `POST` request with an optional encodable body and decodes the response.
    ///
    /// Use this to create a resource or trigger a non-idempotent server action.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` value to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure>

    /// Sends a `PUT` request with an optional encodable body and decodes the response.
    ///
    /// Use this to fully replace a resource.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` value to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func put<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure>

    /// Sends a `PATCH` request with an optional encodable body and decodes the response.
    ///
    /// Use this to partially update a resource.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` value to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure>

    /// Sends a `DELETE` request with an optional encodable body and decodes the response.
    ///
    /// Use this to delete a resource or trigger a delete action with additional context.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` value to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func delete<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure>
}
