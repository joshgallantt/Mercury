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
    private let defaultCachePolicy: URLRequest.CachePolicy
    private let session: MercurySession
    
    // MARK: - Initialization
    
    public init(
        host: String,
        port: Int? = nil,
        defaultHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        let components = URLComponentsParser.parse(host)
        
        self.scheme = components.scheme
        self.host = components.host
        self.port = port ?? components.port
        self.basePath = components.basePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = .shared
        sessionConfiguration.requestCachePolicy = defaultCachePolicy
        
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    internal init(
        host: String,
        port: Int? = nil,
        session: MercurySession,
        defaultHeaders: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ],
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        let components = URLComponentsParser.parse(host)
        
        self.scheme = components.scheme
        self.host = components.host
        self.port = port ?? components.port
        self.basePath = components.basePath
        self.defaultHeaders = defaultHeaders
        self.defaultCachePolicy = defaultCachePolicy
        self.session = session
    }
    
    // MARK: - Public API
    
    public func get<Response: Decodable>(
        path: String,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .GET,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: nil as Data?,
            responseType: responseType
        )
    }
    
    public func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .POST,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            responseType: responseType
        )
    }
    
    public func put<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .PUT,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            responseType: responseType
        )
    }
    
    public func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .PATCH,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            responseType: responseType
        )
    }
    
    public func delete<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        headers: [String: String]? = nil,
        query: [String: String]? = nil,
        fragment: String? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        await performRequest(
            method: .DELETE,
            path: path,
            headers: headers,
            query: query,
            fragment: fragment,
            cachePolicy: cachePolicy,
            body: body,
            responseType: responseType
        )
    }
    
    // MARK: - Private Implementation
    
    private func performRequest<Body: Encodable, Response: Decodable>(
        method: MercuryMethod,
        path: String,
        headers: [String: String]?,
        query: [String: String]?,
        fragment: String?,
        cachePolicy: URLRequest.CachePolicy?,
        body: Body?,
        responseType: Response.Type
    ) async -> Result<MercurySuccess<Response>, MercuryFailure> {
        // Step 1: Validate host
        guard !host.isEmpty else {
            return .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))
        }
        
        // Step 2: Build URL
        guard let url = buildURL(path: path, query: query, fragment: fragment) else {
            return .failure(MercuryFailure(error: .invalidURL, requestSignature: ""))
        }
        
        // Step 3: Encode body only if present
        var bodyData: Data? = nil
        if let body {
            switch encodeBody(body) {
            case .success(let data):
                bodyData = data
            case .failure(let error):
                return .failure(MercuryFailure(error: error, requestSignature: ""))
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
        let signature = generateSignature(for: request)
        
        // Step 6: Execute request
        let networkResult = await executeRequest(request)
        
        // Step 7: Handle response
        return result(
            networkResult: networkResult,
            responseType: responseType,
            signature: signature
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
    
    private func buildFullPath(_ path: String) -> String {
        let cleanBasePath = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        let parts = [cleanBasePath, cleanPath].filter { !$0.isEmpty }
        let fullPath = "/" + parts.joined(separator: "/")
        
        return fullPath.replacingOccurrences(of: "/+", with: "/", options: NSString.CompareOptions.regularExpression)
    }
    
    private func buildQueryItems(from query: [String: String]?) -> [URLQueryItem]? {
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
        guard let customHeaders = customHeaders else {
            return defaultHeaders
        }
        return defaultHeaders.merging(customHeaders) { _, custom in custom }
    }
    
    private func encodeBody<Body: Encodable>(_ body: Body?) -> Result<Data?, MercuryError> {
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
        responseType: Response.Type,
        signature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        switch networkResult {
        case .failure(let error):
            return .failure(MercuryFailure(error: error, requestSignature: signature))
            
        case .success(let (data, httpResponse)):
            return processResponse(
                data: data,
                httpResponse: httpResponse,
                responseType: responseType,
                signature: signature
            )
        }
    }
    
    private func processResponse<Response: Decodable>(
        data: Data,
        httpResponse: HTTPURLResponse,
        responseType: Response.Type,
        signature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        
        if (200...299).contains(httpResponse.statusCode) {
            return decodeResponse(
                data: data,
                httpResponse: httpResponse,
                responseType: responseType,
                signature: signature
            )
        }

        return .failure(
            MercuryFailure(
                error: .server(
                    statusCode: httpResponse.statusCode,
                    data: data
                ),
                requestSignature: signature
            )
        )
    }
    
    private func decodeResponse<Response: Decodable>(
        data: Data,
        httpResponse: HTTPURLResponse,
        responseType: Response.Type,
        signature: String
    ) -> Result<MercurySuccess<Response>, MercuryFailure> {
        do {
            // Handle Data.self
            if responseType == Data.self, let value = data as? Response {
                return .success(MercurySuccess(
                    value: value,
                    httpResponse: httpResponse,
                    requestSignature: signature
                ))
            }
            
            // Handle String.self
            if responseType == String.self, let string = String(data: data, encoding: .utf8), let value = string as? Response {
                return .success(MercurySuccess(
                    value: value,
                    httpResponse: httpResponse,
                    requestSignature: signature
                ))
            }
            
            // Otherwise, try JSON decoding
            let decoded = try JSONDecoder().decode(responseType, from: data)
            return .success(
                MercurySuccess(
                    value: decoded,
                    httpResponse: httpResponse,
                    requestSignature: signature
                )
            )
        } catch {
            let keyPath = extractKeyPath(from: error, for: responseType)
            return .failure(
                MercuryFailure(
                    error: .decodingFailed(
                        namespace: String(describing: responseType),
                        key: keyPath,
                        underlyingError: error
                    ),
                    requestSignature: signature
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
    
    private func generateSignature(for request: URLRequest) -> String {
        var components: [String] = []
        
        // Add method
        components.append(request.httpMethod ?? "GET")
        
        // Add URL
        if let url = request.url?.absoluteString {
            components.append(url)
        }
        
        // Add body hash if present
        if let body = request.httpBody, !body.isEmpty {
            components.append("body:\(hashData(body))")
        }
        
        // Add headers if present
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            components.append("headers:\(canonicalizeHeaders(headers))")
        }
        
        return components.joined(separator: "|")
    }
    
    private func hashData(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
    
    private func canonicalizeHeaders(_ headers: [String: String]) -> String {
        headers
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { "\($0.key.lowercased()):\($0.value)" }
            .joined(separator: "&")
    }
}

