//
//  MockMercury.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//



import Foundation
import Mercury

/// A mock implementation of `MercuryProtocol` designed for testing.
/// Provides stubbing capabilities and call recording.
public final class MockMercury: MercuryProtocol, @unchecked Sendable {
    
    // MARK: - Types
    
    /// Represents a recorded method call with all parameters
    public struct RecordedCall: Equatable {
        public let method: MercuryMethod
        public let path: String
        public let headers: [String: String]?
        public let query: [String: String]?
        public let fragment: String?
        public let cachePolicy: URLRequest.CachePolicy?
        public let hasBody: Bool
        
        public init(
            method: MercuryMethod,
            path: String,
            headers: [String: String]?,
            query: [String: String]?,
            fragment: String?,
            cachePolicy: URLRequest.CachePolicy?,
            hasBody: Bool
        ) {
            self.method = method
            self.path = path
            self.headers = headers
            self.query = query
            self.fragment = fragment
            self.cachePolicy = cachePolicy
            self.hasBody = hasBody
        }
    }
    
    /// Configuration for stubbed responses
    public struct StubbedResponse<T: Decodable> {
        public let result: Result<MercurySuccess<T>, MercuryFailure>
        public let delay: TimeInterval
        
        public init(result: Result<MercurySuccess<T>, MercuryFailure>, delay: TimeInterval = 0) {
            self.result = result
            self.delay = delay
        }
    }
    
    // MARK: - Private Properties
    
    private let lock = NSLock()
    private var _recordedCalls: [RecordedCall] = []
    private var _stubs: [String: Any] = [:]
    
    // MARK: - Public Properties
    
    /// All recorded method calls in chronological order
    public var recordedCalls: [RecordedCall] {
        lock.withLock { _recordedCalls }
    }
    
    /// Number of recorded calls
    public var callCount: Int {
        lock.withLock { _recordedCalls.count }
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Stubbing Methods
    
    /// Stubs a response for a specific method and path combination
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
        
        let success = MercurySuccess(
            value: response,
            httpResponse: httpResponse,
            requestString: "\(method.rawValue) \(path)"
        )
        let stubbedResponse = StubbedResponse(result: .success(success), delay: delay)
        let key = stubKey(method: method, path: path)
        
        lock.withLock {
            _stubs[key] = stubbedResponse
        }
    }
    
    /// Stubs a failure response for a specific method and path combination
    public func stubFailure<T: Decodable>(
        method: MercuryMethod,
        path: String,
        error: MercuryError,
        responseType: T.Type,
        delay: TimeInterval = 0
    ) {
        let failure = MercuryFailure(
            error: error,
            requestString: "\(method.rawValue) \(path)"
        )
        let stubbedResponse = StubbedResponse<T>(result: .failure(failure), delay: delay)
        let key = stubKey(method: method, path: path)
        
        lock.withLock {
            _stubs[key] = stubbedResponse
        }
    }
    
    /// Removes all stubs and recorded calls
    public func reset() {
        lock.withLock {
            _stubs.removeAll()
            _recordedCalls.removeAll()
        }
    }
        
    /// Returns the number of calls made to a specific method and path
    public func callCount(for method: MercuryMethod, path: String) -> Int {
        recordedCalls.count { $0.method == method && $0.path == path }
    }
    
    /// Checks if a specific method and path combination was called
    public func wasCalled(method: MercuryMethod, path: String) -> Bool {
        callCount(for: method, path: path) > 0
    }
    
    // MARK: - MercuryProtocol Implementation
    
    public func get<Response: Decodable>(
        path: String,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .GET,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: false,
            responseType: responseType
        )
    }
    
    public func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .POST,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: body != nil,
            responseType: responseType
        )
    }
    
    public func put<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .PUT,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: body != nil,
            responseType: responseType
        )
    }
    
    public func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .PATCH,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: body != nil,
            responseType: responseType
        )
    }
    
    public func delete<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .DELETE,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: body != nil,
            responseType: responseType
        )
    }
    
    // MARK: - Private Methods
    
    private func performRequest<Response: Decodable>(
        method: MercuryMethod,
        path: String,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        hasBody: Bool,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        
        // Record the call
        let call = RecordedCall(
            method: method,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            hasBody: hasBody
        )
        
        lock.withLock {
            _recordedCalls.append(call)
        }
        
        // Look for stubbed response
        let key = stubKey(method: method, path: path)
        let stubbedResponse: StubbedResponse<Response>? = lock.withLock {
            _stubs[key] as? StubbedResponse<Response>
        }
        
        if let stubbedResponse {
            // Apply delay if specified
            if stubbedResponse.delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(stubbedResponse.delay * 1_000_000_000))
            }
            return stubbedResponse.result
        }
        
        // Default behavior: return a failure indicating no stub was configured
        let failure = MercuryFailure(
            error: .invalidURL,
            requestString: "\(method.rawValue) \(path)"
        )
        
        return .failure(failure)
    }
    
    private func stubKey(method: MercuryMethod, path: String) -> String {
        "\(method.rawValue):\(path)"
    }
}

// MARK: - Extensions

extension MockMercury {
    
    /// Convenience method to stub a GET request
    public func stubGet<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .GET, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }
    
    /// Convenience method to stub a POST request
    public func stubPost<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 201,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .POST, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }
    
    /// Convenience method to stub a PUT request
    public func stubPut<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .PUT, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }
    
    /// Convenience method to stub a PATCH request
    public func stubPatch<T: Decodable>(
        path: String,
        response: T,
        statusCode: Int = 200,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        stub(method: .PATCH, path: path, response: response, statusCode: statusCode, headers: headers, delay: delay)
    }
    
    /// Convenience method to stub a DELETE request
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
