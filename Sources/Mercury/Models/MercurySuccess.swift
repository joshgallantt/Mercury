//
//  MercurySuccess.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation
import CryptoKit

/// Represents a successful HTTP response with a decoded data.
public struct MercurySuccess<Data: Decodable> {
    
    /// The decoded response data.
    public let data: Data

    /// The raw HTTP response metadata.
    public let httpResponse: HTTPURLResponse
    
    /// A  string representing the request
    public let requestString: String

    /// A unique signature representing the request (useful for caching, debugging, etc).
    public var requestSignature: String {
        guard !requestString.isEmpty else {
            return ""
        }
        
        let data = Foundation.Data(requestString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    public init(
        value: Data,
        httpResponse: HTTPURLResponse,
        requestString: String
    ) {
        self.data = value
        self.httpResponse = httpResponse
        self.requestString = requestString
    }
}

