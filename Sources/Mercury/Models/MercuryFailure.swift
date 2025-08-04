//
//  MercuryFailure.swift
//  Mercury
//
//  Created by Josh Gallant on 29/07/2025.
//

import Foundation

/// Represents a failed HTTP request, including a machine-readable error and the request signature.
public struct MercuryFailure: Error, CustomStringConvertible {
    /// The specific failure reason.
    public let error: MercuryError

    /// The signature of the request that failed.
    public let requestSignature: String

    public init(error: MercuryError, requestSignature: String) {
        self.error = error
        self.requestSignature = requestSignature
    }

    /// A textual description of the failure, delegating to the underlying `MercuryError`.
    public var description: String {
        error.description
    }
}
