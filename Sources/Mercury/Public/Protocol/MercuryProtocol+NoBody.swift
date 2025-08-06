//
//  MercuryProtocol+NoBody.swift
//  Mercury
//
//  Created by Josh Gallant on 06/08/2025.
//

import Foundation

extension MercuryProtocol {
    /// Sends a `POST` request without a body and decodes the response.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - decodeInto: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func post<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await post(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: decodeInto
        )
    }

    /// Sends a `PUT` request without a body and decodes the response.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - decodeInto: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func put<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await put(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: decodeInto
        )
    }

    /// Sends a `PATCH` request without a body and decodes the response.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - decodeInto: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func patch<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await patch(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: decodeInto
        )
    }

    /// Sends a `DELETE` request without a body and decodes the response.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///   - decodeInto: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    func delete<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await delete(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeInto: decodeInto
        )
    }
}
