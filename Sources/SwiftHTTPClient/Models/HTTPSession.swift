//
//  HTTPSession.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 12/07/2025.
//

import Foundation

public protocol HTTPSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

