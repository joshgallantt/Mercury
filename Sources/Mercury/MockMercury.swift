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
/// ```
public actor MockMercury: MercuryProtocol {

    // MARK: - Stubbed Results

    private var getResult: Result<MercurySuccess, MercuryFailure> = .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))
    private var postResult: Result<MercurySuccess, MercuryFailure> = .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))
    private var putResult: Result<MercurySuccess, MercuryFailure> = .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))
    private var patchResult: Result<MercurySuccess, MercuryFailure> = .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))
    private var deleteResult: Result<MercurySuccess, MercuryFailure> = .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))

    // MARK: - Recorded Calls

    public private(set) var recordedCalls: [Call] = []

    public enum Call: Sendable, Equatable {
        case get(path: String, headers: [String: String]?, queryItems: [String: String]?, fragment: String?)
        case post(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
        case postEncodable(path: String, headers: [String: String]?, queryItems: [String: String]?, fragment: String?)
        case put(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
        case patch(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
        case delete(path: String, headers: [String: String]?, queryItems: [String: String]?, data: Data?, fragment: String?)
    }

    public init() {}

    // MARK: - Stub Setters

    public func setGetResult(_ value: Result<MercurySuccess, MercuryFailure>) async {
        getResult = value
    }

    public func setPostResult(_ value: Result<MercurySuccess, MercuryFailure>) async {
        postResult = value
    }

    public func setPutResult(_ value: Result<MercurySuccess, MercuryFailure>) async {
        putResult = value
    }

    public func setPatchResult(_ value: Result<MercurySuccess, MercuryFailure>) async {
        patchResult = value
    }

    public func setDeleteResult(_ value: Result<MercurySuccess, MercuryFailure>) async {
        deleteResult = value
    }

    // MARK: - MercuryProtocol Conformance

    public func get(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryFailure> {
        recordedCalls.append(.get(path: path, headers: headers, queryItems: queryItems, fragment: fragment))
        return getResult
    }

    public func post(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        data: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryFailure> {
        recordedCalls.append(.post(path: path, headers: headers, queryItems: queryItems, data: data, fragment: fragment))
        return postResult
    }

    public func post<T: Encodable>(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: T,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) async -> Result<MercurySuccess, MercuryFailure> {
        recordedCalls.append(.postEncodable(path: path, headers: headers, queryItems: queryItems, fragment: fragment))
        return postResult
    }

    public func put(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryFailure> {
        recordedCalls.append(.put(path: path, headers: headers, queryItems: queryItems, data: body, fragment: fragment))
        return putResult
    }

    public func patch(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryFailure> {
        recordedCalls.append(.patch(path: path, headers: headers, queryItems: queryItems, data: body, fragment: fragment))
        return patchResult
    }

    public func delete(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<MercurySuccess, MercuryFailure> {
        recordedCalls.append(.delete(path: path, headers: headers, queryItems: queryItems, data: body, fragment: fragment))
        return deleteResult
    }
}
