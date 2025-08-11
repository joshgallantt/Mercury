//
//  MockMercurySession.swift
//  Mercury
//
//  Created by Josh Gallant on 05/08/2025.
//


import XCTest
@testable import Mercury


public final class MockMercurySession: MercurySession {
    
    enum Scenario {
        case success(Data, URLResponse)
        case error(Error)
    }
    
    private let scenario: Scenario
    
    init(scenario: Scenario, onRequest: ((URLRequest) -> (Data, URLResponse))? = nil) {
        self.scenario = scenario
    }
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        switch scenario {
        case .success(let data, let response):
            return (data, response)
        case .error(let error):
            throw error
        }
    }
}

extension Result {
    var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }
}
