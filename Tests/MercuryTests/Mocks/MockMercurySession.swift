//
//  MockMercurySession.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class MockMercurySession: MercurySession {
    
    // MARK: - Types
    
    enum Scenario {
        case success(Data, URLResponse)
        case error(Error)
    }
    
    // MARK: - Properties
    
    private let scenario: Scenario
    var onRequest: ((URLRequest) -> (Data, URLResponse))?
    
    // MARK: - Initialization
    
    init(scenario: Scenario) {
        self.scenario = scenario
    }
    
    // MARK: - MercurySession
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        // If onRequest is set, use it for custom behavior
        if let onRequest = onRequest {
            let (data, response) = onRequest(request)
            return (data, response)
        }
        
        // Otherwise use the scenario
        switch scenario {
        case .success(let data, let response):
            return (data, response)
        case .error(let error):
            throw error
        }
    }
}
