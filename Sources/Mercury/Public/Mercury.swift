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

    
    // MARK: - Public API
    
    /// Clears all cached responses from `URLCache.shared`.
    ///
    /// - Warning: This will remove **all** cached URL responses from the global shared cache,
    ///   including those created outside of Mercury. This may impact other networking clients,
    ///   libraries, or system requests that rely on the shared cache. Use with caution!
    static func clearSharedURLCache() {
        URLCache.shared.removeAllCachedResponses()
    }

    
    /// Clears the cache used by this Mercury client, if using `.isolated`.
    public func clearCache() {
        urlCache?.removeAllCachedResponses()
    }
    
    public func get<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .GET,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: nil as Data?,
            decodeInto: decodeInto
        )
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
        await performRequest(
            method: .POST,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            decodeInto: decodeInto
        )
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
        await performRequest(
            method: .PUT,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            decodeInto: decodeInto
        )
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
        await performRequest(
            method: .PATCH,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            decodeInto: decodeInto
        )
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
        await performRequest(
            method: .DELETE,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            decodeInto: decodeInto
        )
    }
    
    // MARK: - Private Implementation
    
    func encodeBody<Body: Encodable>(_ body: Body?) -> Result<Data?, MercuryError> {
        guard let body = body else {
            return .success(nil)
        }
        
        do {
            let data = try JSONEncoder().encode(body)
            return .success(data)
        } catch {
            return .failure(.encoding(error))
        }
    }
    
    private func performRequest<Body: Encodable, Response: Decodable>(
        method: MercuryMethod,
        path: String,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        body: Body?,
        decodeInto: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        // Step 1: Validate host
        guard !host.isEmpty else {
            return .failure(MercuryFailure(error: .invalidURL, requestString: ""))
        }
        
        // Step 2: Build URL
        guard let url = buildURL(path: path, query: query, fragment: fragment) else {
            return .failure(MercuryFailure(error: .invalidURL, requestString: ""))
        }
        
        // Step 3: Encode body only if present
        var bodyData: Data? = nil
        if let body {
            switch encodeBody(body) {
            case .success(let data):
                bodyData = data
            case .failure(let error):
                return .failure(MercuryFailure(error: error, requestString: ""))
            }
        }
        
        // Step 4: Build request
        let request = buildRequest(
            url: url,
            method: method,
            headers: headers,
            body: bodyData,
            cachePolicy: cachePolicy
        )
        
        // Step 5: Generate signature
        let requestString = generateCanonicalRequestString(for: request)
        
        // Step 6: Execute request
        let networkResult = await executeRequest(request)
        
        // Step 7: Handle response
        return result(
            networkResult: networkResult,
            decodeInto: decodeInto,
            requestString: requestString
        )
    }
    
    private func buildURL(path: String, query: [String: String]?, fragment: String?) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = buildFullPath(path)
        components.queryItems = buildQueryItems(from: query)
        components.fragment = fragment
        
        return components.url
    }
    
    internal func buildFullPath(_ path: String) -> String {
        let cleanBasePath = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        let parts = [cleanBasePath, cleanPath].filter { !$0.isEmpty }
        let fullPath = "/" + parts.joined(separator: "/")
        
        return fullPath.replacingOccurrences(of: "/+", with: "/", options: NSString.CompareOptions.regularExpression)
    }
    
    internal func buildQueryItems(from query: [String: String]?) -> [URLQueryItem]? {
        guard let query = query, !query.isEmpty else { return nil }
        return query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    private func buildRequest(
        url: URL,
        method: MercuryMethod,
        headers: [String: String]?,
        body: Data?,
        cachePolicy: URLRequest.CachePolicy?
    ) -> URLRequest {
        var request = URLRequest(
            url: url,
            cachePolicy: cachePolicy ?? defaultCachePolicy,
            timeoutInterval: 60
        )
        
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = mergeHeaders(headers)
        
        if let body {
            request.httpBody = body
        }
        
        return request
    }
    
    private func mergeHeaders(_ customHeaders: [String: String]?) -> [String: String] {
        // Step 1: Start with defaults, store mapping of lowercased -> original casing key
        var merged = [String: (originalKey: String, value: String)]()
        for (key, value) in defaultHeaders {
            merged[key.lowercased()] = (key, value)
        }
        // Step 2: For each custom header, override (by lowercased key) and preserve custom's casing
        if let customHeaders = customHeaders {
            for (key, value) in customHeaders {
                merged[key.lowercased()] = (key, value)
            }
        }
        // Step 3: Return dictionary with preserved key casing from winner
        return Dictionary(uniqueKeysWithValues: merged.values.map { ($0.originalKey, $0.value) })
    }

    
    private func executeRequest(_ request: URLRequest) async -> Result<(Data, HTTPURLResponse), MercuryError> {
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
    
    private func result<Response: Decodable>(
        networkResult: Result<(Data, HTTPURLResponse), MercuryError>,
        decodeInto: Response.Type,
        requestString: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        switch networkResult {
        case .failure(let error):
            return .failure(MercuryFailure(error: error, requestString: requestString))
            
        case .success(let (data, httpResponse)):
            return processResponse(
                data: data,
                httpResponse: httpResponse,
                decodeInto: decodeInto,
                signature: requestString
            )
        }
    }
    
    private func processResponse<Response: Decodable>(
        data: Data,
        httpResponse: HTTPURLResponse,
        decodeInto: Response.Type,
        signature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        
        if (200...299).contains(httpResponse.statusCode) {
            return decodeResponse(
                data: data,
                httpResponse: httpResponse,
                decodeInto: decodeInto,
                signature: signature
            )
        }

        return .failure(
            MercuryFailure(
                error: .server(
                    statusCode: httpResponse.statusCode,
                    data: data
                ),
                httpResponse: httpResponse,
                requestString: signature
            )
        )
    }
    
    private func decodeResponse<Response: Decodable>(
        data: Data,
        httpResponse: HTTPURLResponse,
        decodeInto: Response.Type,
        signature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        do {
            // Handle Data.self
            if decodeInto == Data.self, let value = data as? Response {
                return .success(MercurySuccess(
                    value: value,
                    httpResponse: httpResponse,
                    requestString: signature
                ))
            }
            
            // Handle String.self
            if decodeInto == String.self, let string = String(data: data, encoding: .utf8), let value = string as? Response {
                return .success(MercurySuccess(
                    value: value,
                    httpResponse: httpResponse,
                    requestString: signature
                ))
            }
            
            // Otherwise, try JSON decoding
            let decoded = try JSONDecoder().decode(decodeInto, from: data)
            return .success(
                MercurySuccess(
                    value: decoded,
                    httpResponse: httpResponse,
                    requestString: signature
                )
            )
        } catch {
            let keyPath = extractKeyPath(from: error, for: decodeInto)
            return .failure(
                MercuryFailure(
                    error: .decoding(
                        namespace: String(describing: decodeInto),
                        key: keyPath,
                        underlyingError: error
                    ),
                    requestString: signature
                )
            )
        }
    }
    
    private func extractKeyPath<Response: Decodable>(
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
    
    private func buildKeyPath(_ path: [CodingKey]) -> String {
        path.map { $0.stringValue }.joined(separator: ".")
    }
    
    internal func generateCanonicalRequestString(for request: URLRequest) -> String {
        var components: [String] = []
        
        // Add method
        components.append(request.httpMethod ?? "GET")
        
        // Add URL
        if let url = request.url?.absoluteString {
            components.append(url)
        }
        
        // Add headers if present
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            components.append("headers:\(canonicalizeHeaders(headers))")
        }
        
        return components.joined(separator: "|")
    }
    
    private func canonicalizeHeaders(_ headers: [String: String]) -> String {
        headers
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { "\($0.key.lowercased()):\($0.value)" }
            .joined(separator: "&")
    }
}

