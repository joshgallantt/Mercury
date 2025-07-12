//
//  HTTPClient.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation

public actor HTTPClient {
    private let session: HTTPSession
    private let scheme: String
    private let host: String
    private let port: Int?
    private let basePath: String
    private let commonHeaders: [String: String]

    // MARK: - Initializers

    public init(
        host: String,
        port: Int? = nil,
        commonHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    ) {
        let (scheme, host, basePath) = HTTPClient.normalizeHost(host)
        self.scheme = scheme
        self.host = host
        self.port = port
        self.basePath = basePath
        self.commonHeaders = commonHeaders

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = .shared
        configuration.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: configuration)
    }

    public init(
        host: String,
        port: Int? = nil,
        session: HTTPSession,
        commonHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    ) {
        let (scheme, host, basePath) = HTTPClient.normalizeHost(host)
        self.scheme = scheme
        self.host = host
        self.port = port
        self.session = session
        self.basePath = basePath
        self.commonHeaders = commonHeaders
    }

    // MARK: - URL Normalization

    internal nonisolated static func normalizeHost(_ input: String) -> (scheme: String, host: String, basePath: String) {
        // Try parsing as URL, fallback to plain host
        if let url = URL(string: input), let host = url.host {
            let scheme = url.scheme ?? "https"
            let path = url.path
            // Normalize path: collapse multiple slashes, remove trailing slash
            let normalizedBasePath = path
                .replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let finalBasePath = normalizedBasePath.isEmpty ? "" : "/" + normalizedBasePath
            return (scheme, host, finalBasePath)
        } else {
            // Remove protocol prefix manually, just in case (handles invalid URLs)
            let sanitized = input.replacingOccurrences(of: #"^https?://"#, with: "", options: .regularExpression)
            let parts = sanitized.split(separator: "/", omittingEmptySubsequences: false)
            let host = parts.first.map(String.init) ?? ""
            let basePath = parts.dropFirst().joined(separator: "/")
            // Normalize basePath
            let normalizedBasePath = basePath
                .replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let finalBasePath = normalizedBasePath.isEmpty ? "" : "/" + normalizedBasePath
            return ("https", host, finalBasePath)
        }
    }

    internal nonisolated static func normalizePath(_ basePath: String, _ path: String) -> String {
        // Join basePath and path with a single slash
        let parts = [basePath, path]
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
            .filter { !$0.isEmpty }
        let joined = "/" + parts.joined(separator: "/")
        // Collapse multiple slashes into one everywhere
        let normalized = joined.replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
        return normalized
    }

    // MARK: - HTTP Methods

    public func get(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        await request(path: path, method: .GET, headers: headers, queryItems: queryItems, fragment: fragment, cachePolicy: cachePolicy)
    }

    public func post<T: Encodable>(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: T,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        encoder: JSONEncoder = JSONEncoder()
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        do {
            let data = try encoder.encode(body)
            return await post(
                path,
                headers: headers,
                queryItems: queryItems,
                body: data,
                fragment: fragment,
                cachePolicy: cachePolicy
            )
        } catch {
            return .failure(.encoding(error))
        }
    }

    public func post(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        data: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        await request(path: path, method: .POST, headers: headers, queryItems: queryItems, body: data, fragment: fragment, cachePolicy: cachePolicy)
    }

    public func put(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        await request(path: path, method: .PUT, headers: headers, queryItems: queryItems, body: body, fragment: fragment, cachePolicy: cachePolicy)
    }

    public func patch(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        await request(path: path, method: .PATCH, headers: headers, queryItems: queryItems, body: body, fragment: fragment, cachePolicy: cachePolicy)
    }

    public func delete(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        await request(path: path, method: .DELETE, headers: headers, queryItems: queryItems, body: body, fragment: fragment, cachePolicy: cachePolicy)
    }

    // MARK: - Request Handling

    private func request(
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        guard let url = buildURL(path: path, queryItems: queryItems, fragment: fragment) else {
            return .failure(.invalidURL)
        }

        let request = buildRequest(url: url, method: method, headers: headers, body: body, cachePolicy: cachePolicy)
        return await send(request: request)
    }

    internal nonisolated func buildURL(path: String, queryItems: [String: String]?, fragment: String?) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = HTTPClient.normalizePath(basePath, path)
        components.queryItems = queryItems?.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.fragment = fragment
        return components.url
    }

    internal nonisolated func buildRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        cachePolicy: URLRequest.CachePolicy
    ) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 60)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = commonHeaders.merging(headers ?? [:]) { _, custom in custom }
        request.httpBody = body
        return request
    }

    private func send(request: URLRequest) async -> Result<HTTPSuccess, HTTPFailure> {
        let session = self.session

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            if (200...299).contains(httpResponse.statusCode) {
                return .success(HTTPSuccess(data: data, response: httpResponse))
            } else {
                return .failure(.server(statusCode: httpResponse.statusCode, data: data))
            }
        } catch {
            return .failure(.transport(error))
        }
    }
}
