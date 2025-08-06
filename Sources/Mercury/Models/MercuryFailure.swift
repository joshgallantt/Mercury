//
//  MercuryFailure.swift
//  Mercury
//
//  Created by Josh Gallant on 29/07/2025.
//

import Foundation
import CryptoKit

/// Represents a failed HTTP request, including a machine-readable error and the request signature.
public struct MercuryFailure: Error, CustomStringConvertible {
    
    /// The decoded response data.
    public let error: MercuryError

    /// The raw HTTP response metadata, if one was provided.
    public var httpResponse: HTTPURLResponse? = nil
    
    /// A  string representing the request
    public let requestString: String

    /// A unique signature representing the request (useful for caching, debugging, etc).
    public var requestSignature: String {
        guard !requestString.isEmpty else {
            return ""
        }
        
        let data = Data(requestString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    public init(
        error: MercuryError,
        httpResponse: HTTPURLResponse? = nil,
        requestString: String
    ) {
        self.error = error
        self.httpResponse = httpResponse
        self.requestString = requestString
    }

    /// A textual description of the failure, delegating to the underlying `MercuryError`.
    public var description: String {
        error.description
    }
}
