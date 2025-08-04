//
//  MercurySessionTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class MercurySessionTests: XCTestCase {

    func test_givenSuccessScenario_whenDataCalled_thenReturnsExpectedDataAndResponse() async throws {
        // Given
        let expectedData = "hello".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let request = URLRequest(url: URL(string: "https://test.com")!)
        let session = MockMercurySession(scenario: .success(expectedData, expectedResponse))

        // When
        let (data, response) = try await session.data(for: request)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual((response as? HTTPURLResponse)?.url, expectedResponse.url)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, expectedResponse.statusCode)
    }

    func test_givenErrorScenario_whenDataCalled_thenThrowsError() async {
        // Given
        enum DummyError: Error, Equatable { case test }
        let request = URLRequest(url: URL(string: "https://fail.com")!)
        let session = MockMercurySession(scenario: .error(DummyError.test))

        // When/Then
        do {
            _ = try await session.data(for: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DummyError)
        }
    }

    func test_givenOnRequestClosure_whenDataCalled_thenUsesClosure() async throws {
        // Given
        let expectedData = "closure".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(
            url: URL(string: "https://closure.com")!,
            statusCode: 202,
            httpVersion: nil,
            headerFields: nil
        )!
        let request = URLRequest(url: URL(string: "https://closure.com")!)
        let session = MockMercurySession(scenario: .error(NSError(domain: "irrelevant", code: 0)))
        session.onRequest = { _ in (expectedData, expectedResponse) }

        // When
        let (data, response) = try await session.data(for: request)

        // Then
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, expectedResponse.statusCode)
        XCTAssertEqual((response as? HTTPURLResponse)?.url, expectedResponse.url)
    }
}
