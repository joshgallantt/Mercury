//
//  MercurySuccess.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation
import CryptoKit

/// Represents a successful HTTP response with a decoded value.
public struct MercurySuccess<Value: Decodable> {
    /// The decoded response value.
    public let value: Value

    /// The raw HTTP response metadata.
    public let httpResponse: HTTPURLResponse
    
    /// A  string representing the request
    public let requestString: String

    /// A unique signature representing the request (useful for caching, debugging, etc).
    public var requestSignature: String {
        let data = Data(requestString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    public init(
        value: Value,
        httpResponse: HTTPURLResponse,
        requestString: String
    ) {
        self.value = value
        self.httpResponse = httpResponse
        self.requestString = requestString
    }
}
