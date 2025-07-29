//
//  MockMercurySession.swift
//  Mercury
//
//  Created by Josh Gallant on 12/07/2025.
//

import XCTest
@testable import Mercury

final class MockMercurySession: MercurySession {
    enum Scenario {
        case success(Data, URLResponse)
        case error(Error)
    }
    
    let scenario: Scenario
    
    var onRequest: ((URLRequest) -> (Data, URLResponse)?)?

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let onRequest = onRequest, let result = onRequest(request) {
            return result
        }
        switch scenario {
        case .success(let data, let response):
            return (data, response)
        case .error(let error):
            throw error
        }
    }
}
