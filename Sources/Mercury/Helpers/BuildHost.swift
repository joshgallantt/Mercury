//
//  BuildHost.swift
//  Mercury
//
//  Created by Josh Gallant on 14/07/2025.
//


import Foundation

internal struct BuildHost {

    /// Parses the input string and extracts scheme, host, port (if any), and basePath
    /// - Input: "https://example.com:8080/api/foo"
    /// - Output: ("https", "example.com", 8080, "/api/foo")
    internal static func execute(_ input: String) throws -> (scheme: String, host: String, port: Int?, basePath: String) {
        let (scheme, rest) = try extractSchemeAndRest(input)
        // rest might be: "example.com:8080/api/foo"
        let (hostWithPort, basePath) = extractHostAndBasePath(from: rest)
        // hostWithPort: "example.com:8080", basePath: "api/foo"
        let (host, port) = extractHostAndPort(hostWithPort)
        // host: "example.com", port: 8080
        let finalBasePath = normalizeBasePath(basePath)
        // finalBasePath: "/api/foo"
        return (scheme, host, port, finalBasePath)
    }

    /// Splits input into scheme and the rest
    /// - Input: "https://example.com:8080/api"
    /// - Output: ("https", "example.com:8080/api")
    internal static func extractSchemeAndRest(_ input: String) throws -> (String, String) {
        guard let regex = try? NSRegularExpression(pattern: #"^([a-zA-Z][a-zA-Z0-9+.-]*)://"#, options: []) else {
            throw NSError(domain: "Invalid regex", code: 0, userInfo: nil)
        }

        let nsInput = input as NSString
        let match = regex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: nsInput.length))
        if let match,
           let schemeRange = Range(match.range(at: 1), in: input),
           let wholeRange = Range(match.range, in: input) {
            let scheme = String(input[schemeRange])
            let rest = String(input[wholeRange.upperBound...])
            return (scheme, rest)
        } else {
            // Default to https if no scheme
            return ("https", input)
        }
    }

    /// Splits rest into hostWithPort and basePath
    /// - Input: "example.com:8080/api/foo"
    /// - Output: ("example.com:8080", "api/foo")
    /// - Input: "[::1]:3000/v1"
    /// - Output: ("[::1]:3000", "v1")
    /// - Input: "example.com"
    /// - Output: ("example.com", "")
    internal static func extractHostAndBasePath(from rest: String) -> (hostWithPort: String, basePath: String) {
        let trimmed = rest.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
        let hostWithPort = parts.first.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
        let basePath = parts.dropFirst().joined(separator: "/")
        return (hostWithPort, basePath)
    }

    /// Splits hostWithPort into host and port (if present)
    /// - Input: "example.com:8080" => ("example.com", 8080)
    /// - Input: "[::1]:3000"      => ("[::1]", 3000)
    /// - Input: "example.com"     => ("example.com", nil)
    /// - Input: "[::1]"           => ("[::1]", nil)
    internal static func extractHostAndPort(_ hostWithPort: String) -> (host: String, port: Int?) {
        // Handle IPv6, e.g. [::1]:8080 or [2001:db8::1]:1234
        if hostWithPort.hasPrefix("[") {
            if let endBracket = hostWithPort.firstIndex(of: "]") {
                let host = String(hostWithPort[..<hostWithPort.index(after: endBracket)])
                let remainder = hostWithPort[hostWithPort.index(after: endBracket)...]
                if remainder.hasPrefix(":") {
                    let portStr = remainder.dropFirst()
                    if let port = Int(portStr) {
                        return (host, port)
                    }
                }
                return (host, nil)
            }
        }
        // Handle host:port (non-IPv6)
        let parts = hostWithPort.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2, let port = Int(parts[1]) {
            return (String(parts[0]), port)
        }
        return (hostWithPort, nil)
    }

    /// Cleans up basePath for use in URLs
    /// - Input: "api/foo"
    /// - Output: "/api/foo"
    /// - Input: ""
    /// - Output: ""
    internal static func normalizeBasePath(_ basePath: String) -> String {
        let normalized = basePath
            .replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? "" : "/" + normalized
    }
}
