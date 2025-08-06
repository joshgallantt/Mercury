//
//  MercuryProtocol+Optionals.swift
//  Mercury
//
//  Created by Josh Gallant on 06/08/2025.
//

import Foundation

public extension MercuryProtocol {
    
    /// Sends a `GET` request and decodes the response into the specified type.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL (e.g., `"/search/multi"`).
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters (e.g., `["q": "inception"]`).
    ///   - fragment: Optional URL fragment (e.g., `#section`).
    ///   - cachePolicy: Optional caching behavior override. Defaults to the client's default if `nil`.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func get<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await get(
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: responseType
        )
    }
    
    /// Sends a `POST` request with an optional encodable body and decodes the response.
    ///
    /// Use this to create a resource or trigger a non-idempotent server action.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` data to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await post(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: responseType
        )
    }
    
    /// Sends a `PUT` request with an optional encodable body and decodes the response.
    ///
    /// Use this to fully replace a resource.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` data to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func put<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await put(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: responseType
        )
    }
    
    /// Sends a `PATCH` request with an optional encodable body and decodes the response.
    ///
    /// Use this to partially update a resource.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` data to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await patch(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: responseType
        )
    }
    
    /// Sends a `DELETE` request with an optional encodable body and decodes the response.
    ///
    /// Use this to delete a resource or trigger a delete action with additional context.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` data to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - responseType: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func delete<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await delete(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: responseType
        )
    }
}
