//
//  MercuryProtocol+NoResponse.swift
//  Mercury
//
//  Created by Josh Gallant on 06/08/2025.
//

import Foundation

public extension MercuryProtocol {
    
    /// Sends a `POST` request with an optional encodable body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` data to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func post<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await post(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: Data.self
        )
    }
    
    /// Sends a `PUT` request with an optional encodable body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` data to send as JSON in the request body.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func put<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await put(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: Data.self
        )
    }
    
    /// Sends a `PATCH` request with an optional encodable body.
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
    /// - Returns: A result containing raw data and metadata, or a failure.
    func patch<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await patch(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: Data.self
        )
    }
    
    /// Sends a `DELETE` request with an optional encodable body.
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
    /// - Returns: A result containing raw data and metadata, or a failure.
    func delete<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await delete(
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            responseType: Data.self
        )
    }
}
