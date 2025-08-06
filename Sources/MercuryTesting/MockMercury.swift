//
//  MockMercury.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//

import Foundation
import Mercury

public final class MockMercury: MercuryProtocol, @unchecked Sendable {

    // MARK: - Types

    public struct RecordedCall: Equatable {
        public let method: MercuryMethod
        public let path: String
        public let headers: [String: String]?
        public let query: [String: String]?
        public let fragment: String?
        public let cachePolicy: URLRequest.CachePolicy?
        public let hasBody: Bool
    }

    private struct StubbedResponse<T: Decodable> {
        let result: Result<MercurySuccess<T>, MercuryFailure>
        let delay: TimeInterval
    }

    // MARK: - Private Properties

    private let lock = NSLock()
    private var recorded: [RecordedCall] = []
    private var stubs: [String: Any] = [:]

    // MARK: - Public API

    public init() {}

    public func reset() {
        lock.withLock {
            recorded.removeAll()
            stubs.removeAll()
        }
    }

    public func stub<T: Decodable>(
        method: MercuryMethod,
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        let url = URL(string: "https://example.com\(path)")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        let result = MercurySuccess(value: response, httpResponse: httpResponse, requestString: "\(method.rawValue) \(path)")
        let stub = StubbedResponse(result: .success(result), delay: delay)
        lock.withLock { stubs[stubKey(method: method, path: path)] = stub }
    }

    public func stubFailure<T: Decodable>(
        method: MercuryMethod,
        path: String,
        error: MercuryError,
        decodeInto: T.Type,
        delay: TimeInterval = 0
    ) {
        let failure = MercuryFailure(error: error, requestString: "\(method.rawValue) \(path)")
        let stub = StubbedResponse<T>(result: .failure(failure), delay: delay)
        lock.withLock { stubs[stubKey(method: method, path: path)] = stub }
    }

    public func callCount(for method: MercuryMethod, path: String) -> Int {
        lock.withLock {
            recorded.filter { $0.method == method && $0.path == path }.count
        }
    }

    public func wasCalled(method: MercuryMethod, path: String) -> Bool {
        callCount(for: method, path: path) > 0
    }

    public var recordedCalls: [RecordedCall] {
        lock.withLock { recorded }
    }

    // MARK: - MercuryProtocol Implementation

    public func get<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await perform(.GET, path, headers, query, fragment, cachePolicy, false, decodeInto)
    }

    public func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await perform(.POST, path, headers, query, fragment, cachePolicy, body != nil, decodeInto)
    }

    public func put<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await perform(.PUT, path, headers, query, fragment, cachePolicy, body != nil, decodeInto)
    }

    public func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await perform(.PATCH, path, headers, query, fragment, cachePolicy, body != nil, decodeInto)
    }

    public func delete<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await perform(.DELETE, path, headers, query, fragment, cachePolicy, body != nil, decodeInto)
    }

    // MARK: - Private

    private func perform<Response: Decodable>(
        _ method: MercuryMethod,
        _ path: String,
        _ headers: [String: String]?,
        _ query: [String: String]?,
        _ fragment: String?,
        _ cachePolicy: URLRequest.CachePolicy?,
        _ hasBody: Bool,
        _ decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        let call = RecordedCall(
            method: method,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: hasBody
        )
        lock.withLock { recorded.append(call) }
        let key = stubKey(method: method, path: path)
        let stub: StubbedResponse<Response>? = lock.withLock { stubs[key] as? StubbedResponse<Response> }
        if let stub, stub.delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(stub.delay * 1_000_000_000))
            return stub.result
        }
        if let stub { return stub.result }
        let failure = MercuryFailure(error: .invalidURL, requestString: "\(method.rawValue) \(path)")
        return .failure(failure)
    }

    private func stubKey(method: MercuryMethod, path: String) -> String {
        "\(method.rawValue):\(path)"
    }
}

// MARK: - Convenience

extension MockMercury {
    public func stubGet<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .GET, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }

    public func stubPost<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 201,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .POST, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }

    public func stubPut<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .PUT, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }

    public func stubPatch<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .PATCH, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }

    public func stubDelete<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 204,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .DELETE, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }
}

// MARK: - Thread Safety

private extension NSLock {
    @discardableResult
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
