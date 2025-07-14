//
//  BuildURL.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 14/07/2025.
//


import Foundation

internal struct BuildURL {
    internal static func execute(
        scheme: String,
        host: String,
        port: Int?,
        basePath: String,
        path: String,
        queryItems: [String: String]? = nil,
        fragment: String? = nil
    ) -> URL? {
        guard !host.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = normalizePath(basePath, path)
        components.queryItems = queryItems?.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.fragment = fragment
        return components.url
    }

    private static func normalizePath(_ basePath: String, _ path: String) -> String {
        let parts = [basePath, path]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))) }
            .filter { !$0.isEmpty }
        let joined = "/" + parts.joined(separator: "/")
        let normalized = joined.replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
        return normalized
    }
}
