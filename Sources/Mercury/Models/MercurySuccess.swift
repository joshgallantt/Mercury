//
//  MercurySuccess.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation

/// Represents a successful HTTP response with a decoded value.
public struct MercurySuccess<Value: Decodable> {
    /// The decoded response value.
    public let value: Value

    /// The raw HTTP response metadata.
    public let httpResponse: HTTPURLResponse

    /// A unique signature representing the request (useful for caching, debugging, etc).
    public let requestSignature: String

    public init(value: Value, httpResponse: HTTPURLResponse, requestSignature: String) {
        self.value = value
        self.httpResponse = httpResponse
        self.requestSignature = requestSignature
    }
}
