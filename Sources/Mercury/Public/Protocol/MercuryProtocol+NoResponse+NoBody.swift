//
//  MercuryProtocol+NoResponse+NoBody.swift
//  Mercury
//
//  Created by Josh Gallant on 06/08/2025.
//

import Foundation

extension MercuryProtocol {
    
    /// Sends a `GET` request without a body or expected response type.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func get(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await get(
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: Data.self
        )
    }
    
    /// Sends a `POST` request without a body or expected response type.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func post(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await post(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: Data.self
        )
    }

    /// Sends a `PUT` request without a body or expected response type.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func put(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await put(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: Data.self
        )
    }

    /// Sends a `PATCH` request without a body or expected response type.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func patch(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await patch(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: Data.self
        )
    }

    /// Sends a `DELETE` request without a body or expected response type.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    func delete(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await delete(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: Data.self
        )
    }
}
