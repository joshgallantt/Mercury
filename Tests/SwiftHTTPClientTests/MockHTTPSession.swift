//
//  MockHTTPSession.swift
//  SwiftHTTPClient
//
//  Created by Josh Gallant on 12/07/2025.
//


import XCTest
@testable import SwiftHTTPClient

final class MockHTTPSession: HTTPSession {
    enum Scenario {
        case success(Data, URLResponse)
        case error(Error)
    }
    
    let scenario: Scenario

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        switch scenario {
        case .success(let data, let response):
            return (data, response)
        case .error(let error):
            throw error
        }
    }
}
