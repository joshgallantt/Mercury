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
    private let defaultHeaders: [String: String]
    private let defaultCachePolicy: URLRequest.CachePolicy

    // MARK: - Initializers

    public init(
        host: String,
        port: Int? = nil,
        defaultHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        let (scheme, host, basePath) = HTTPClient.normalizeHost(host)
        self.scheme = scheme
        self.host = host
        self.port = port
        self.basePath = basePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = .shared
        configuration.requestCachePolicy = defaultCachePolicy
        self.session = URLSession(configuration: configuration)
    }

    public init(
        host: String,
        port: Int? = nil,
        session: HTTPSession,
        defaultHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        let (scheme, host, basePath) = HTTPClient.normalizeHost(host)
        self.scheme = scheme
        self.host = host
        self.port = port
        self.session = session
        self.basePath = basePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
    }

    // MARK: - HTTP Methods

    public func get(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        return await request(
            path: path,
            method: .GET,
            headers: headers,
            queryItems: queryItems,
            fragment: fragment,
            cachePolicy: cachePolicy ?? defaultCachePolicy
        )
    }

    public func post(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        data: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        return await request(
            path: path,
            method: .POST,
            headers: headers,
            queryItems: queryItems,
            body: data,
            fragment: fragment,
            cachePolicy: cachePolicy ?? defaultCachePolicy
        )
    }

    public func post<T: Encodable>(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: T,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        do {
            let data = try encoder.encode(body)
            return await self.post(
                path,
                headers: headers,
                queryItems: queryItems,
                data: data,
                fragment: fragment,
                cachePolicy: cachePolicy
            )
        } catch {
            return .failure(.encoding(error))
        }
    }

    public func put(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        return await request(
            path: path,
            method: .PUT,
            headers: headers,
            queryItems: queryItems,
            body: body,
            fragment: fragment,
            cachePolicy: cachePolicy ?? defaultCachePolicy
        )
    }

    public func patch(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        return await request(
            path: path,
            method: .PATCH,
            headers: headers,
            queryItems: queryItems,
            body: body,
            fragment: fragment,
            cachePolicy: cachePolicy ?? defaultCachePolicy
        )
    }

    public func delete(
        _ path: String,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        return await request(
            path: path,
            method: .DELETE,
            headers: headers,
            queryItems: queryItems,
            body: body,
            fragment: fragment,
            cachePolicy: cachePolicy ?? defaultCachePolicy
        )
    }

    // MARK: - Request Handling

    internal func request(
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        guard
            let url = buildURL(path: path, queryItems: queryItems, fragment: fragment),
            let host = url.host, !host.isEmpty
        else {
            return .failure(.invalidURL)
        }
        let request = buildRequest(url: url, method: method, headers: headers, body: body, cachePolicy: cachePolicy)
        return await send(request: request)
    }

    // MARK: URL Building

    internal nonisolated static func normalizeHost(_ input: String) -> (scheme: String, host: String, basePath: String) {
        let (scheme, rest) = extractSchemeAndRest(input)
        let (host, basePath) = extractHostAndBasePath(from: rest)
        let finalBasePath = normalizeBasePath(basePath)
        return (scheme, host, finalBasePath)
    }

    internal nonisolated static func extractSchemeAndRest(_ input: String) -> (String, String) {
        let regex = try! NSRegularExpression(pattern: #"^([a-zA-Z][a-zA-Z0-9+.-]*)://"#, options: [])
        let nsInput = input as NSString
        let match = regex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: nsInput.length))

        if let match, let schemeRange = Range(match.range(at: 1), in: input),
           let wholeRange = Range(match.range, in: input) {
            let scheme = String(input[schemeRange])
            let rest = String(input[wholeRange.upperBound...])
            return (scheme, rest)
        } else {
            return ("https", input)
        }
    }

    internal nonisolated static func extractHostAndBasePath(from rest: String) -> (String, String) {
        let trimmed = rest.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
        let host = parts.first.map(String.init) ?? ""
        let basePath = parts.dropFirst().joined(separator: "/")
        return (host, basePath)
    }

    internal nonisolated static func normalizeBasePath(_ basePath: String) -> String {
        let normalized = basePath
            .replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? "" : "/" + normalized
    }

    internal nonisolated static func normalizePath(_ basePath: String, _ path: String) -> String {
        let parts = [basePath, path]
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/"))) }
            .filter { !$0.isEmpty }
        let joined = "/" + parts.joined(separator: "/")
        let normalized = joined.replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
        return normalized
    }

    internal nonisolated func buildURL(path: String, queryItems: [String: String]?, fragment: String?) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = HTTPClient.normalizePath(basePath, path)
        components.queryItems = queryItems?.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.fragment = fragment
        let result = components.url
        return result
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
        let mergedHeaders = defaultHeaders.merging(headers ?? [:]) { _, custom in custom }
        request.allHTTPHeaderFields = mergedHeaders
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
