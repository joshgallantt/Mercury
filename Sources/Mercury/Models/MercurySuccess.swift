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
    
    public init(
        value: Data,
        httpResponse: HTTPURLResponse
    ) {
        self.data = value
        self.httpResponse = httpResponse
    }
}

