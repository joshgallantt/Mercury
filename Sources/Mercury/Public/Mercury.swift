//
//  Mercury.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation
import CryptoKit

public struct Mercury: MercuryProtocol {
    // MARK: - Properties
    
    private let scheme: String
    private let host: String
    private let port: Int?
    private let basePath: String
    private let defaultHeaders: [String: String]
    private let session: MercurySession
    
    // Cache
    private let cache: MercuryCache
    private let urlCache: URLCache?
    private let defaultCachePolicy: URLRequest.CachePolicy
    
    // MARK: - Initialization
    
    /// Creates a new Mercury HTTP client instance targeting a specific host, with configurable headers and caching.
    ///
    /// This initializer parses the host string for scheme, host, port, and base path components, allowing for convenient usage such as:
    /// ```swift
    /// Mercury(host: "https://api.example.com/v1")
    /// ```
    /// - Parameters:
    ///   - host: The API host, optionally including scheme, port, and base path. E.g., `"https://api.example.com:8080/v1"`.
    ///   - port: Overrides the port parsed from `host`. If not provided, the port from `host` is used if present.
    ///   - defaultHeaders: Default HTTP headers to include with every request. The default is `["Accept": "application/json", "Content-Type": "application/json"]`.
    ///   - defaultCachePolicy: The cache policy applied to all requests unless overridden per-request. Defaults to `.useProtocolCachePolicy`.
    ///   - cache: Controls response caching. Use `.shared` for system-wide caching, or `.isolated` to isolate cache usage per Mercury instance with custom memory/disk sizes.
    ///
    /// If `cache` is `.isolated`, a private `URLCache` is created for this instance. Otherwise, the global shared cache is used.
    ///
    /// Example:
    /// ```swift
    /// let client = Mercury(
    ///     host: "https://api.example.com/v2",
    ///     defaultHeaders: [
    ///         "Authorization": "Bearer <token>"
    ///     ],
    ///     cache: .isolated(memorySize: 2_000_000, diskSize: 10_000_000)
    /// )
    /// ```
    public init(
        host: String,
        port: Int? = nil,
        defaultHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        cache: MercuryCache = .shared
    ) {
        let components = URLComponentsParser.parse(host)
        self.scheme = components.scheme
        self.host = components.host
        self.port = port ?? components.port
        self.basePath = components.basePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
        self.cache = cache

        let (resolvedCache, resolvedSession): (URLCache?, URLSession)
        switch cache {
        case .shared:
            resolvedCache = nil
            let config = URLSessionConfiguration.default
            config.urlCache = .shared
            config.requestCachePolicy = defaultCachePolicy
            resolvedSession = URLSession(configuration: config)
        case .isolated(let memory, let disk):
            let cache = URLCache(memoryCapacity: memory, diskCapacity: disk)
            resolvedCache = cache
            let config = URLSessionConfiguration.default
            config.urlCache = cache
            config.requestCachePolicy = defaultCachePolicy
            resolvedSession = URLSession(configuration: config)
        }

        self.urlCache = resolvedCache
        self.session = resolvedSession
    }

    // Internal for injection/testing
    internal init(
        host: String,
        port: Int? = nil,
        session: MercurySession,
        defaultHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        cache: MercuryCache = .shared,
        urlCache: URLCache? = nil
    ) {
        let components = URLComponentsParser.parse(host)
        self.scheme = components.scheme
        self.host = components.host
        self.port = port ?? components.port
        self.basePath = components.basePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
        self.cache = cache
        self.urlCache = urlCache
        self.session = session
    }

    
    // MARK: - Public API - Cache Management
    
    /// Clears all cached responses from `URLCache.shared`.
    ///
    /// - Warning: This will remove **all** cached URL responses from the global shared cache,
    ///   including those created outside of Mercury. This may impact other networking clients,
    ///   libraries, or system requests that rely on the shared cache. Use with caution!
    public static func clearSharedURLCache() {
        URLCache.shared.removeAllCachedResponses()
    }

    /// Clears the cache used by this Mercury client, if using `.isolated`.
    public func clearCache() {
        urlCache?.removeAllCachedResponses()
    }
    
    // MARK: - Public API - Request Building
    
    /// Builds a MercuryRequest for any HTTP method
    public func buildRequest<Body: Encodable>(
        method: MercuryMethod,
        path: String,
        body: Body? = nil,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) throws -> MercuryRequest {
        let bodyData = try encodeBody(body)
        let finalHeaders = mergeHeaders(headers)
        let fullPath = buildFullPath(path)
        
        return MercuryRequest(
            method: method,
            scheme: scheme,
            host: host,
            port: port,
            path: fullPath,
            headers: finalHeaders,
            query: query,
            fragment: fragment,
            body: bodyData,
            cachePolicy: cachePolicy ?? defaultCachePolicy
        )
    }
    
    /// Convenience builder for GET requests
    public func buildGet(
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
    
    /// Convenience builder for POST requests
    public func buildPost<Body: Encodable>(
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
    
    /// Convenience builder for PUT requests
    public func buildPut<Body: Encodable>(
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
    
    /// Convenience builder for PATCH requests
    public func buildPatch<Body: Encodable>(
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
    
    /// Convenience builder for DELETE requests
    public func buildDelete<Body: Encodable>(
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
    
    // MARK: - Public API - Request Execution
    
    /// Executes a pre-built MercuryRequest and decodes the response
    public func execute<Response: Decodable>(
        _ request: MercuryRequest,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        // Validate request
        guard !request.host.isEmpty else {
            return .failure(MercuryFailure(
                error: .invalidURL,
                requestString: request.string,
                requestSignature: request.signature
            ))
        }
        
        // Build URLRequest
        let urlRequestResult = buildURLRequest(from: request)
        switch urlRequestResult {
        case .failure(let error):
            return .failure(MercuryFailure(
                error: error,
                requestString: request.string,
                requestSignature: request.signature
            ))
        case .success(let urlRequest):
            // Execute and decode
            return await executeAndDecode(
                urlRequest,
                decodeTo: decodeTo,
                requestString: request.string,
                requestSignature: request.signature
            )
        }
    }
    
    /// Executes a pre-built MercuryRequest returning raw Data
    public func execute(
        _ request: MercuryRequest
    ) async -> Result<MercurySuccess<Data>, MercuryFailure> {
        await execute(request, decodeTo: Data.self)
    }
    
    // MARK: - Protocol Implementation (Convenience Methods)
    
    public func get<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .GET,
            path: path,
            body: nil as MercuryEmptyBody?,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeTo: decodeTo
        )
    }

    public func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .POST,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeTo: decodeTo
        )
    }

    public func put<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .PUT,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeTo: decodeTo
        )
    }

    public func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .PATCH,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeTo: decodeTo
        )
    }

    public func delete<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .DELETE,
            path: path,
            body: body,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            decodeTo: decodeTo
        )
    }
    
    // MARK: - Private Helpers
    
    /// Unified method for performing requests through build -> execute pipeline
    internal func performRequest<Body: Encodable, Response: Decodable>(
        method: MercuryMethod,
        path: String,
        body: Body?,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        decodeTo: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        do {
            let request = try buildRequest(
                method: method,
                path: path,
                body: body,
                headers: headers,
                query: query,
                fragment: fragment,
                cachePolicy: cachePolicy
            )
            return await execute(request, decodeTo: decodeTo)
        } catch let error as MercuryError {
            return .failure(
                MercuryFailure(
                    error: error,
                    requestString: "\(method.rawValue) \(path)",
                    requestSignature: ""
                )
            )
        } catch {
            return .failure(
                MercuryFailure(
                    error: .transport(error),
                    requestString: "\(method.rawValue) \(path)",
                    requestSignature: ""
                )
            )
        }
    }
    
    /// Encodes the request body to Data
    internal func encodeBody<Body: Encodable>(_ body: Body?) throws -> Data? {
        guard let body = body else { return nil }
        
        do {
            return try JSONEncoder().encode(body)
        } catch {
            throw MercuryError.encoding(error)
        }
    }
    
    /// Builds the full path by combining base path and request path
    internal func buildFullPath(_ path: String) -> String {
        let cleanBasePath = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        let parts = [cleanBasePath, cleanPath].filter { !$0.isEmpty }
        let fullPath = "/" + parts.joined(separator: "/")
        
        return fullPath.replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
    }
    
    /// Converts query dictionary to URLQueryItem array
    internal func buildQueryItems(from query: [String: String]?) -> [URLQueryItem]? {
        guard let query = query, !query.isEmpty else { return nil }
        return query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    /// Merges custom headers with default headers, preserving custom header casing
    internal func mergeHeaders(_ customHeaders: [String: String]?) -> [String: String] {
        var merged = [String: (originalKey: String, value: String)]()
        
        // Add defaults with their original casing
        for (key, value) in defaultHeaders {
            merged[key.lowercased()] = (key, value)
        }
        
        // Override with custom headers, preserving their casing
        if let customHeaders = customHeaders {
            for (key, value) in customHeaders {
                merged[key.lowercased()] = (key, value)
            }
        }
        
        // Return dictionary with preserved casing
        return Dictionary(uniqueKeysWithValues: merged.values.map { ($0.originalKey, $0.value) })
    }
    
    /// Builds a URLRequest from a MercuryRequest
    internal func buildURLRequest(from request: MercuryRequest) -> Result<URLRequest, MercuryError> {
        var components = URLComponents()
        components.scheme = request.scheme
        components.host = request.host
        components.port = request.port
        components.path = request.path
        components.queryItems = buildQueryItems(from: request.query)
        components.fragment = request.fragment
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        var urlRequest = URLRequest(
            url: url,
            cachePolicy: request.cachePolicy,
            timeoutInterval: 60
        )
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body
        
        return .success(urlRequest)
    }
    
    /// Executes URLRequest and decodes the response
    internal func executeAndDecode<Response: Decodable>(
        _ urlRequest: URLRequest,
        decodeTo: Response.Type,
        requestString: String,
        requestSignature: String
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        // Execute network request
        let networkResult = await executeNetworkRequest(urlRequest)
        
        // Process and decode response
        switch networkResult {
        case .failure(let error):
            return .failure(
                MercuryFailure(
                    error: error,
                    requestString: requestString,
                    requestSignature: requestSignature
                )
            )
            
        case .success(let (data, httpResponse)):
            return processResponse(
                data: data,
                httpResponse: httpResponse,
                decodeTo: decodeTo,
                requestString: requestString,
                requestSignature: requestSignature
            )
        }
    }
    
    /// Executes the network request via URLSession
    internal func executeNetworkRequest(_ request: URLRequest) async -> Result<(Data, HTTPURLResponse), MercuryError> {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            return .success((data, httpResponse))
        } catch {
            return .failure(.transport(error))
        }
    }
    
    /// Processes the HTTP response and checks status code
    internal func processResponse<Response: Decodable>(
        data: Data,
        httpResponse: HTTPURLResponse,
        decodeTo: Response.Type,
        requestString: String,
        requestSignature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        
        guard (200...299).contains(httpResponse.statusCode) else {
            return .failure(
                MercuryFailure(
                    error: .server(
                        statusCode: httpResponse.statusCode,
                        data: data
                    ),
                    httpResponse: httpResponse,
                    requestString: requestString,
                    requestSignature: requestSignature
                )
            )
        }
        
        return decodeResponse(
            data: data,
            httpResponse: httpResponse,
            decodeTo: decodeTo,
            requestString: requestString,
            requestSignature: requestSignature
        )
    }
    
    /// Decodes the response data into the expected type
    internal func decodeResponse<Response: Decodable>(
        data: Data,
        httpResponse: HTTPURLResponse,
        decodeTo: Response.Type,
        requestString: String,
        requestSignature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        do {
            let decoded: Response
            
            switch decodeTo {
            case is Data.Type:
                // Special case: return raw Data
                guard let value = data as? Response else {
                    throw DecodingError.typeMismatch(
                        Response.self,
                        DecodingError.Context(codingPath: [], debugDescription: "Failed to cast Data")
                    )
                }
                decoded = value
                
            case is String.Type:
                // Special case: decode as String
                guard let string = String(data: data, encoding: .utf8),
                      let value = string as? Response else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: [], debugDescription: "Failed to decode String from UTF-8")
                    )
                }
                decoded = value
                
            default:
                // Standard JSON decoding
                decoded = try JSONDecoder().decode(decodeTo, from: data)
            }
            
            return .success(
                MercurySuccess(
                    value: decoded,
                    httpResponse: httpResponse,
                    requestString: requestString,
                    requestSignature: requestSignature
                )
            )
        } catch {
            let keyPath = extractKeyPath(from: error, for: decodeTo)
            return .failure(
                MercuryFailure(
                    error: .decoding(
                        namespace: String(describing: decodeTo),
                        key: keyPath,
                        underlyingError: error
                    ),
                    httpResponse: httpResponse,
                    requestString: requestString,
                    requestSignature: requestSignature
                )
            )
        }
    }
    
    /// Extracts the key path from a DecodingError for better error messages
    internal func extractKeyPath<Response: Decodable>(
        from error: Error,
        for type: Response.Type
    ) -> String {
        guard let decodingError = error as? DecodingError else {
            return "root"
        }
        
        switch decodingError {
        case .keyNotFound(let key, let context):
            return buildKeyPath(context.codingPath + [key])
        case .typeMismatch(_, let context),
             .valueNotFound(_, let context),
             .dataCorrupted(let context):
            return buildKeyPath(context.codingPath)
        @unknown default:
            return "root"
        }
    }
    
    /// Builds a dot-notation key path from CodingKey array
    internal func buildKeyPath(_ path: [CodingKey]) -> String {
        guard !path.isEmpty else { return "root" }
        return path.map { $0.stringValue }.joined(separator: ".")
    }
}
