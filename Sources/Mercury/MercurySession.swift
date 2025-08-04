//
//  MercurySession.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//

import Foundation

/// Abstracts URLSession for injection/mocking in tests.
protocol MercurySession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: MercurySession {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        // This already matches the URLSession API, so just forward the call
        try await self.data(for: request, delegate: nil)
    }
}
