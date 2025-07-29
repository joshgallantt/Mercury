//
//  MockMercury.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//

import Foundation

/// A mock implementation of `MercuryProtocol` for use in unit and integration tests.
///
/// `MockMercury` allows developers to stub HTTP responses and record calls made to HTTP methods.
/// This type is intended **only for testing** and should not be used in production code. Use this
/// mock to isolate your repositories, services, or view models from real networking in your tests.
///
/// Example usage:
/// ```swift
/// let mock = MockMercury()
/// await mock.setGetResult(.success(...))
/// // Inject into your repository or service for testing.
/// ```
public actor MockMercury: MercuryProtocol {

    // MARK: - Stubbed Results

    /// The stubbed result to return for `get` calls.
    private var getResult: Result<MercurySuccess, MercuryError> = .failure(.invalidURL)

    /// The stubbed result to return for `post` calls.
    private var postResult: Result<MercurySuccess, MercuryError> = .failure(.invalidURL)

    /// The stubbed result to return for `put` calls.
    private var putResult: Result<MercurySuccess, MercuryError> = .failure(.invalidURL)

    /// The stubbed result to return for `patch` calls.
    private var patchResult: Result<MercurySuccess, MercuryError> = .failure(.invalidURL)

    /// The stubbed result to return for `delete` calls.
    private var deleteResult: Result<MercurySuccess, MercuryError> = .failure(.invalidURL)

    // MARK: - Recorded Calls

    /// Records each call made to the mock for later inspection in tests.
    public private(set) var recordedCalls: [Call] = []

    /// Represents a call made to any of the HTTP methods.
    public enum Call: Sendable, Equatable {
        case get(path: String, headers: [String: String]?, queryItems: [String: String]?, fragment: String?)
        case post(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
        case postEncodable(path: String, headers: [String: String]?, queryItems: [String: String]?, fragment: String?)
        case put(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
        case patch(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
        case delete(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
    }

    /// Initializes a new, empty mock.
    public init() {}

    // MARK: - Public Async Setters

    /// Sets the stubbed result for `get` calls.
    public func setGetResult(_ value: Result<MercurySuccess, MercuryError>) async {
        getResult = value
    }

    /// Sets the stubbed result for `post` calls.
    public func setPostResult(_ value: Result<MercurySuccess, MercuryError>) async {
        postResult = value
    }

    /// Sets the stubbed result for `put` calls.
    public func setPutResult(_ value: Result<MercurySuccess, MercuryError>) async {
        putResult = value
    }

    /// Sets the stubbed result for `patch` calls.
    public func setPatchResult(_ value: Result<MercurySuccess, MercuryError>) async {
        patchResult = value
    }

    /// Sets the stubbed result for `delete` calls.
    public func setDeleteResult(_ value: Result<MercurySuccess, MercuryError>) async {
        deleteResult = value
    }

    // MARK: - MercuryProtocol

    /// Simulates an HTTP GET request and records the call.
    ///
    /// - Parameters are as documented in `MercuryProtocol`.
    /// - Returns: The value of `getResult`, which can be set in your tests.
    public func get(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryError> {
        recordedCalls.append(.get(path: path, headers: headers, queryItems: queryItems, fragment: fragment))
        return getResult
    }

    /// Simulates an HTTP POST request with raw data and records the call.
    ///
    /// - Parameters are as documented in `MercuryProtocol`.
    /// - Returns: The value of `postResult`, which can be set in your tests.
    public func post(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        data: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryError> {
        recordedCalls.append(.post(path: path, headers: headers, queryItems: queryItems, data: data, fragment: fragment))
        return postResult
    }

    /// Simulates an HTTP POST request with an Encodable body and records the call.
    ///
    /// - Parameters are as documented in `MercuryProtocol`.
    /// - Returns: The value of `postResult`, which can be set in your tests.
    public func post<T: Encodable>(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: T,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) async -> Result<MercurySuccess, MercuryError> {
        recordedCalls.append(.postEncodable(path: path, headers: headers, queryItems: queryItems, fragment: fragment))
        return postResult
    }

    /// Simulates an HTTP PUT request and records the call.
    ///
    /// - Parameters are as documented in `MercuryProtocol`.
    /// - Returns: The value of `putResult`, which can be set in your tests.
    public func put(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryError> {
        recordedCalls.append(.put(path: path, headers: headers, queryItems: queryItems, data: body, fragment: fragment))
        return putResult
    }

    /// Simulates an HTTP PATCH request and records the call.
    ///
    /// - Parameters are as documented in `MercuryProtocol`.
    /// - Returns: The value of `patchResult`, which can be set in your tests.
    public func patch(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryError> {
        recordedCalls.append(.patch(path: path, headers: headers, queryItems: queryItems, data: body, fragment: fragment))
        return patchResult
    }

    /// Simulates an HTTP DELETE request and records the call.
    ///
    /// - Parameters are as documented in `MercuryProtocol`.
    /// - Returns: The value of `deleteResult`, which can be set in your tests.
    public func delete(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryError> {
        recordedCalls.append(.delete(path: path, headers: headers, queryItems: queryItems, data: body, fragment: fragment))
        return deleteResult
    }
}
