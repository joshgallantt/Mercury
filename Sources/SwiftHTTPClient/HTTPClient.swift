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
    private let hasValidHost: Bool

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
        var parsedScheme = "https"
        var parsedHost = ""
        var parsedPort: Int? = nil
        var parsedBasePath = ""
        var isValid = true

        do {
            let (scheme, host, hostPort, basePath) = try BuildHost.execute(host)
            parsedScheme = scheme
            parsedHost = host
            parsedPort = port ?? hostPort  // Explicit port argument wins
            parsedBasePath = basePath
            isValid = !host.isEmpty
        } catch {
            isValid = false
        }

        self.scheme = parsedScheme
        self.host = parsedHost
        self.port = parsedPort
        self.basePath = parsedBasePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
        self.hasValidHost = isValid

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
        var parsedScheme = "https"
        var parsedHost = ""
        var parsedPort: Int? = nil
        var parsedBasePath = ""
        var isValid = true

        do {
            let (scheme, host, hostPort, basePath) = try BuildHost.execute(host)
            parsedScheme = scheme
            parsedHost = host
            parsedPort = port ?? hostPort
            parsedBasePath = basePath
            isValid = !host.isEmpty
        } catch {
            isValid = false
        }

        self.scheme = parsedScheme
        self.host = parsedHost
        self.port = parsedPort
        self.session = session
        self.basePath = parsedBasePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
        self.hasValidHost = isValid
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

    internal func buildURL(
        path: String,
        queryItems: [String: String]?,
        fragment: String?
    ) -> URL? {
        guard hasValidHost else { return nil }
        return BuildURL.execute(
            scheme: scheme,
            host: host,
            port: port,
            basePath: basePath,
            path: path,
            queryItems: queryItems,
            fragment: fragment
        )
    }

    internal func buildRequest(
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

    internal func request(
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        queryItems: [String: String]? = nil,
        body: Data? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy
    ) async -> Result<HTTPSuccess, HTTPFailure> {
        guard hasValidHost,
              let url = buildURL(path: path, queryItems: queryItems, fragment: fragment),
              let urlHost = url.host, !urlHost.isEmpty else {
            return .failure(.invalidURL)
        }
        let request = buildRequest(url: url, method: method, headers: headers, body: body, cachePolicy: cachePolicy)
        return await send(request: request)
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
