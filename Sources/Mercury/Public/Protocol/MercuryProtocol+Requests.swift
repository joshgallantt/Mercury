//
//  MercuryProtocol+Requests.swift
//  Mercury
//
//  Created by Josh Gallant on 12/08/2025.
//


import Foundation

public extension MercuryProtocol {
    
    // MARK: - Request Building
    
    /// Builds a MercuryRequest for any HTTP method.
    ///
    /// This is the core request builder that all other builders delegate to.
    ///
    /// - Parameters:
    ///   - method: The HTTP method (GET, POST, PUT, PATCH, DELETE).
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` body to send as JSON.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` ready for execution.
    /// - Throws: `MercuryError.encoding` if body encoding fails.
    func buildRequest<Body: Encodable>(
        method: MercuryMethod,
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        // Default implementation requires conforming types to implement this
        // Mercury struct implements this directly
        fatalError("buildRequest must be implemented by conforming types")
    }
    
    /// Builds a GET request.
    ///
    /// GET requests typically don't have a body and are used for retrieving resources.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for GET.
    /// - Throws: `MercuryError` if request building fails.
    func buildGet(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildRequest(
            method: .GET,
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a POST request with an optional body.
    ///
    /// POST requests are typically used for creating new resources or submitting data.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` body to send as JSON.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for POST.
    /// - Throws: `MercuryError.encoding` if body encoding fails.
    func buildPost<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildRequest(
            method: .POST,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a PUT request with an optional body.
    ///
    /// PUT requests are typically used for updating/replacing entire resources.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` body to send as JSON.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for PUT.
    /// - Throws: `MercuryError.encoding` if body encoding fails.
    func buildPut<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildRequest(
            method: .PUT,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a PATCH request with an optional body.
    ///
    /// PATCH requests are typically used for partial updates to resources.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` body to send as JSON.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for PATCH.
    /// - Throws: `MercuryError.encoding` if body encoding fails.
    func buildPatch<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildRequest(
            method: .PATCH,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a DELETE request with an optional body.
    ///
    /// DELETE requests are typically used for removing resources.
    /// While bodies in DELETE requests are uncommon, they are supported for APIs that require them.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - body: An optional `Encodable` body to send as JSON.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for DELETE.
    /// - Throws: `MercuryError.encoding` if body encoding fails.
    func buildDelete<Body: Encodable>(
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildRequest(
            method: .DELETE,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    // MARK: - Request Execution
    
    /// Executes a pre-built MercuryRequest and decodes the response.
    ///
    /// This method takes a `MercuryRequest` built using one of the builder methods
    /// and executes it, returning the decoded response or an error.
    ///
    /// - Parameters:
    ///   - request: The `MercuryRequest` to execute.
    ///   - decodeTo: The expected `Decodable` response type.
    ///
    /// - Returns: A result containing the decoded response and metadata, or a failure.
    ///
    /// Example:
    /// ```swift
    /// let request = try client.buildGet(path: "/users")
    /// let result = await client.execute(request, decodeTo: [User].self)
    /// ```
    func execute<Response: Decodable>(
        _ request: MercuryRequest,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        // Default implementation requires conforming types to implement this
        // Mercury struct implements this directly
        fatalError("execute must be implemented by conforming types")
    }
    
    /// Executes a pre-built MercuryRequest returning raw Data.
    ///
    /// This is useful when you need the raw response data without decoding,
    /// such as for binary data or when you want to handle decoding manually.
    ///
    /// - Parameter request: The `MercuryRequest` to execute.
    ///
    /// - Returns: A result containing raw data and metadata, or a failure.
    ///
    /// Example:
    /// ```swift
    /// let request = try client.buildGet(path: "/image.png")
    /// let result = await client.execute(request)
    /// if case .success(let response) = result {
    ///     let imageData = response.data
    /// }
    /// ```
    func execute(
        _ request: MercuryRequest
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await execute(request, decodeTo: Data.self)
    }
}

// MARK: - Convenience Overloads

public extension MercuryProtocol {
    
    /// Builds a POST request without a body.
    ///
    /// Convenience method for POST requests that don't require a request body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for POST without a body.
    /// - Throws: `MercuryError` if request building fails.
    func buildPost(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildPost(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a PUT request without a body.
    ///
    /// Convenience method for PUT requests that don't require a request body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for PUT without a body.
    /// - Throws: `MercuryError` if request building fails.
    func buildPut(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildPut(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a PATCH request without a body.
    ///
    /// Convenience method for PATCH requests that don't require a request body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for PATCH without a body.
    /// - Throws: `MercuryError` if request building fails.
    func buildPatch(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildPatch(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
    
    /// Builds a DELETE request without a body.
    ///
    /// Convenience method for DELETE requests that don't require a request body.
    ///
    /// - Parameters:
    ///   - path: The relative path to append to the base URL.
    ///   - headers: Optional HTTP headers to include in the request.
    ///   - query: Optional query parameters to include in the URL.
    ///   - fragment: Optional URL fragment.
    ///   - cachePolicy: Optional caching behavior override.
    ///
    /// - Returns: A `MercuryRequest` configured for DELETE without a body.
    /// - Throws: `MercuryError` if request building fails.
    func buildDelete(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        try buildDelete(
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy
        )
    }
}
