//
//  HTTPFailure.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation

public enum HTTPFailure: Error, CustomStringConvertible, Sendable {
    case invalidURL
    case server(statusCode: Int, data: Data?)
    case invalidResponse
    case transport(Error)
    case encoding(Error)

    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .server(let code, let data):
            if let data, let string = String(data: data, encoding: .utf8), !string.isEmpty {
                return "Server returned error status code: \(code)\nServer response body:\n\(string)"
            } else {
                return "Server returned error status code: \(code)"
            }
        case .invalidResponse:
            return "Invalid or unexpected response from server"
        case .transport(let error):
            return "Transport error: \(error.localizedDescription)"
        case .encoding(let error):
            return "Encoding error: \(error.localizedDescription)"
        }
    }
}
