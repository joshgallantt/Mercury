//
//  URLComponentsParser.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//

import Foundation

/// Parses a URL string into its scheme, host, port, and normalized base path components.
internal struct URLComponentsParser {
    
    /// Extracts the scheme, host, port, and base path from a given URL-like string.
    /// - Parameter input: The input string, e.g. "https://api.example.com:8080/foo/bar"
    /// - Returns: Components: scheme, host, optional port, and normalized base path (starting with `/` or empty).
    static func parse(_ input: String) -> (scheme: String, host: String, port: Int?, basePath: String) {
        let (scheme, restAfterScheme) = extractScheme(from: input)
        let (hostPortPart, pathPart) = splitHostAndPath(from: restAfterScheme)
        let (host, port) = splitHostAndPort(from: hostPortPart)
        let basePath = normalizeBasePath(pathPart)
        return (scheme: scheme, host: host, port: port, basePath: basePath)
    }
    
    /// Returns the scheme and the remainder of the string after the scheme (if any).
    private static func extractScheme(from input: String) -> (scheme: String, rest: String) {
        let pattern = #"^([a-zA-Z][a-zA-Z0-9+.-]*)://"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: input, range: NSRange(location: 0, length: input.utf16.count)),
            let schemeRange = Range(match.range(at: 1), in: input),
            let restRange = Range(match.range, in: input)
        else {
            // Default to HTTPS if no scheme present
            return ("https", input)
        }
        let scheme = String(input[schemeRange])
        let rest = String(input[restRange.upperBound...])
        return (scheme, rest)
    }
    
    /// Splits the string into the "host[:port]" part and the path part.
    private static func splitHostAndPath(from input: String) -> (hostPort: String, path: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstSlash = trimmed.firstIndex(of: "/") else {
            return (hostPort: trimmed, path: "")
        }
        let hostPort = String(trimmed[..<firstSlash])
        let path = String(trimmed[firstSlash...])
        return (hostPort: hostPort, path: path)
    }
    
    /// Splits host[:port] into host and port, with support for IPv6.
    private static func splitHostAndPort(from hostPort: String) -> (host: String, port: Int?) {
        // Handle IPv6 "[address]:port"
        if hostPort.hasPrefix("["), let endIndex = hostPort.firstIndex(of: "]") {
            let host = String(hostPort[...endIndex])
            let remainder = hostPort[hostPort.index(after: endIndex)...]
            if remainder.hasPrefix(":"), let port = Int(remainder.dropFirst()) {
                return (host, port)
            }
            return (host, nil)
        }
        // Handle regular host:port
        let parts = hostPort.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2, let port = Int(parts[1]) {
            return (String(parts[0]), port)
        }
        return (hostPort, nil)
    }
    
    /// Normalizes the path to always start with a single "/", or returns "" for empty.
    private static func normalizeBasePath(_ path: String) -> String {
        let normalized = path
            .replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? "" : "/" + normalized
    }
}
