//
//  MercurySession.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation

internal protocol MercurySession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: MercurySession {}

