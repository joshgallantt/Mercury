//
//  MercuryError.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation

public enum MercuryError: Error, CustomStringConvertible {
    /// The constructed URL was invalid.
    case invalidURL

    /// The server returned a non-2xx response.
    case server(statusCode: Int, data: Data?)

    /// The response was malformed or not an `HTTPURLResponse`.
    case invalidResponse

    /// A transport-layer failure occurred (e.g., timeout, network unavailable).
    case transport(Error)

    /// The request body failed to encode as JSON.
    case encoding(Error)

    /// The response body could not be decoded into the expected type.
    case decodingFailed(namespace: String, key: String, underlyingError: Error)

    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"

        case .server(let statusCode, let data):
            let statusDescription: String
            switch statusCode {
            case 400: statusDescription = "400 Bad Request"
            case 401: statusDescription = "401 Unauthorized"
            case 403: statusDescription = "403 Forbidden"
            case 404: statusDescription = "404 Not Found"
            case 409: statusDescription = "409 Conflict"
            case 422: statusDescription = "422 Unprocessable Entity"
            case 429: statusDescription = "429 Too Many Requests"
            case 500: statusDescription = "500 Internal Server Error"
            case 502: statusDescription = "502 Bad Gateway"
            case 503: statusDescription = "503 Service Unavailable"
            case 504: statusDescription = "504 Gateway Timeout"
            default: statusDescription = "Server returned status code \(statusCode)"
            }

            if let data, let string = String(data: data, encoding: .utf8), !string.isEmpty {
                return "\(statusDescription): \(string)"
            } else {
                return statusDescription
            }

        case .invalidResponse:
            return "Invalid or unexpected response from server"

        case .transport(let error):
            return "Transport error: \(error.localizedDescription)"

        case .encoding(let error):
            return "Encoding error: \(error.localizedDescription)"

        case let .decodingFailed(namespace, key, underlyingError):
            return "Decoding failed in '\(namespace)' for key '\(key)': \(underlyingError.localizedDescription)"
        }
    }
}
