//
//  MercuryFailure.swift
//  Mercury
//
//  Created by Josh Gallant on 29/07/2025.
//


public struct MercuryFailure: Error, Sendable {
    public let error: MercuryError
    public let requestSignature: String
}
