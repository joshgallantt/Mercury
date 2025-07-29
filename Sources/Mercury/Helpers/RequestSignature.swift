//
//  RequestSignature.swift
//  Mercury
//
//  Created by Josh Gallant on 29/07/2025.
//


import Foundation
import CryptoKit

internal struct RequestSignature {
    internal static func generate(for request: URLRequest) -> String {
        let method = request.httpMethod ?? "GET"
        let urlString = request.url?.absoluteString ?? ""

        var components: [String] = [method, urlString]

        if let body = request.httpBody, !body.isEmpty {
            components.append("body:\(hash(body))")
        }

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let headerString = canonicalize(headers)
            components.append("headers:\(headerString)")
        }

        return components.joined(separator: "|")
    }

    private static func hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func canonicalize(_ headers: [String: String]) -> String {
        headers
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { "\($0.key.lowercased()):\($0.value)" }
            .joined(separator: "&")
    }
}
