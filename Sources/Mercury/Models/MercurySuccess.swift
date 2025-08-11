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
    public var requestSignature: String
    
    public init(
        value: Data,
        httpResponse: HTTPURLResponse,
        requestString: String,
        requestSignature: String
    ) {
        self.data = value
        self.httpResponse = httpResponse
        self.requestString = requestString
        self.requestSignature = requestSignature
    }
}

