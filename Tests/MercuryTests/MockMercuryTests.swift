//
//  MockMercuryTests.swift
//  Mercury
//
//  Created by Josh Gallant on 04/08/2025.
//


import XCTest
@testable import Mercury

final class MockMercuryTests: XCTestCase {
    
    private var mockMercury: MockMercury!
    
    override func setUp() {
        super.setUp()
        mockMercury = Mercury.mock()
    }
    
    override func tearDown() {
        mockMercury = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func test_givenMockMercury_whenInitialized_thenRecordedCallsIsEmpty() {
        // Given
        let mock = Mercury.mock()
        
        // When
        let recordedCalls = mock.recordedCalls
        
        // Then
        XCTAssertTrue(recordedCalls.isEmpty)
        XCTAssertEqual(mock.callCount, 0)
    }
    
    func test_givenMockMercury_whenGetCalled_thenCallIsRecorded() async {
        // Given
        struct User: Codable {
            let id: Int
            let name: String
        }
        
        // When
        _ = await mockMercury.get(
            path: "/users/123",
            headers: ["Authorization": "Bearer token"],
            query: ["include": "profile"],
            fragment: nil,
            cachePolicy: .reloadIgnoringLocalCacheData,
            responseType: User.self
        )
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 1)
        XCTAssertTrue(mockMercury.wasCalled(method: .GET, path: "/users/123"))
        
        let lastCall = mockMercury.lastCall
        XCTAssertEqual(lastCall?.method, .GET)
        XCTAssertEqual(lastCall?.path, "/users/123")
        XCTAssertEqual(lastCall?.headers?["Authorization"], "Bearer token")
        XCTAssertEqual(lastCall?.query?["include"], "profile")
        XCTAssertFalse(lastCall?.hasBody ?? true)
    }
    
    func test_givenMockMercury_whenPostCalledWithBody_thenCallIsRecordedWithBody() async {
        // Given
        struct CreateUserRequest: Codable {
            let name: String
            let email: String
        }
        
        struct User: Codable {
            let id: Int
            let name: String
            let email: String
        }
        
        let requestBody = CreateUserRequest(name: "John Doe", email: "john@example.com")
        
        // When
        _ = await mockMercury.post(
            path: "/users",
            body: requestBody,
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 1)
        XCTAssertTrue(mockMercury.wasCalled(method: .POST, path: "/users"))
        XCTAssertTrue(mockMercury.lastCall?.hasBody ?? false)
    }
    
    func test_givenMockMercury_whenPutCalledWithBody_thenCallIsRecordedWithBody() async {
        // Given
        struct UpdateUserRequest: Codable { let name: String }
        struct User: Codable { let id: Int; let name: String }
        let body = UpdateUserRequest(name: "Updated Name")

        // When
        _ = await mockMercury.put(
            path: "/users/456",
            body: body,
            headers: ["Custom": "Header"],
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )

        // Then
        XCTAssertEqual(mockMercury.callCount, 1)
        XCTAssertTrue(mockMercury.wasCalled(method: .PUT, path: "/users/456"))
        XCTAssertEqual(mockMercury.lastCall?.headers?["Custom"], "Header")
        XCTAssertTrue(mockMercury.lastCall?.hasBody ?? false)
    }

    func test_givenMockMercury_whenPatchCalledWithBody_thenCallIsRecordedWithBody() async {
        // Given
        struct PatchUserRequest: Codable { let name: String }
        struct User: Codable { let id: Int; let name: String }
        let body = PatchUserRequest(name: "Patched Name")

        // When
        _ = await mockMercury.patch(
            path: "/users/789",
            body: body,
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )

        // Then
        XCTAssertEqual(mockMercury.callCount, 1)
        XCTAssertTrue(mockMercury.wasCalled(method: .PATCH, path: "/users/789"))
        XCTAssertTrue(mockMercury.lastCall?.hasBody ?? false)
    }

    func test_givenMockMercury_whenDeleteCalled_thenCallIsRecorded() async {
        // Given
        struct User: Codable { let id: Int }
        // When
        _ = await mockMercury.delete(
            path: "/users/999",
            body: nil as Data?,
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        // Then
        XCTAssertEqual(mockMercury.callCount, 1)
        XCTAssertTrue(mockMercury.wasCalled(method: .DELETE, path: "/users/999"))
        XCTAssertFalse(mockMercury.lastCall?.hasBody ?? true)
    }

    // MARK: - Stubbing for PUT, PATCH, DELETE

    func test_givenStubbedPutResponse_whenPutCalled_thenReturnsStub() async {
        // Given
        struct User: Codable, Equatable { let id: Int; let name: String }
        let expected = User(id: 42, name: "Updated Name")
        mockMercury.stubPut(path: "/users/42", response: expected)
        // When
        let result = await mockMercury.put(path: "/users/42", body: expected, headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        // Then
        switch result {
        case .success(let value):
            XCTAssertEqual(value.value, expected)
            XCTAssertEqual(value.httpResponse.statusCode, 200)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func test_givenStubbedPatchResponse_whenPatchCalled_thenReturnsStub() async {
        // Given
        struct User: Codable, Equatable { let id: Int; let name: String }
        let expected = User(id: 52, name: "Patched Name")
        mockMercury.stubPatch(path: "/users/52", response: expected)
        // When
        let result = await mockMercury.patch(path: "/users/52", body: expected, headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        // Then
        switch result {
        case .success(let value):
            XCTAssertEqual(value.value, expected)
            XCTAssertEqual(value.httpResponse.statusCode, 200)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func test_givenStubbedDeleteResponse_whenDeleteCalled_thenReturnsStub() async {
        // Given
        struct DeleteResponse: Codable, Equatable { let status: String }
        let expected = DeleteResponse(status: "ok")
        mockMercury.stubDelete(path: "/users/53", response: expected)
        // When
        let result = await mockMercury.delete(
            path: "/users/53",
            body: nil as Data?,
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: DeleteResponse.self
        )
        // Then
        switch result {
        case .success(let value):
            XCTAssertEqual(value.value, expected)
            XCTAssertEqual(value.httpResponse.statusCode, 204)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    // MARK: - Failure Stubbing for PUT, PATCH, DELETE

    func test_givenStubbedFailure_whenPutCalled_thenReturnsFailure() async {
        // Given
        struct User: Codable { let id: Int }
        mockMercury.stubFailure(method: .PUT, path: "/users/404", error: .server(statusCode: 404, data: nil), responseType: User.self)
        // When
        let result = await mockMercury.put(path: "/users/404", body: User(id: 404), headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let failure):
            if case .server(let statusCode, _) = failure.error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected server error")
            }
        }
    }

    func test_givenStubbedFailure_whenPatchCalled_thenReturnsFailure() async {
        // Given
        struct User: Codable { let id: Int }
        mockMercury.stubFailure(method: .PATCH, path: "/users/404", error: .server(statusCode: 404, data: nil), responseType: User.self)
        // When
        let result = await mockMercury.patch(path: "/users/404", body: User(id: 404), headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let failure):
            if case .server(let statusCode, _) = failure.error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected server error")
            }
        }
    }

    func test_givenStubbedFailure_whenDeleteCalled_thenReturnsFailure() async {
        // Given
        struct User: Codable { let id: Int }
        mockMercury.stubFailure(method: .DELETE, path: "/users/404", error: .server(statusCode: 404, data: nil), responseType: User.self)
        // When
        let result = await mockMercury.delete(
            path: "/users/404",
            body: nil as Data?,
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let failure):
            if case .server(let statusCode, _) = failure.error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected server error")
            }
        }
    }

    
    // MARK: - Stubbing Tests
    
    func test_givenStubbedResponse_whenGetCalled_thenReturnsStubResponse() async {
        // Given
        struct User: Codable, Equatable {
            let id: Int
            let name: String
        }
        
        let expectedUser = User(id: 123, name: "John Doe")
        mockMercury.stubGet(path: "/users/123", response: expectedUser)
        
        // When
        let result = await mockMercury.get(
            path: "/users/123",
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        
        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, expectedUser)
            XCTAssertEqual(success.httpResponse.statusCode, 200)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }
    
    func test_givenStubbedFailure_whenGetCalled_thenReturnsFailure() async {
        // Given
        struct User: Codable {
            let id: Int
            let name: String
        }
        
        let _ = MercuryFailure(
            error: .server(statusCode: 404, data: nil),
            requestSignature: "GET /users/999"
        )
        
        mockMercury.stubFailure(
            method: .GET,
            path: "/users/999",
            error: .server(statusCode: 404, data: nil),
            responseType: User.self
        )
        
        // When
        let result = await mockMercury.get(
            path: "/users/999",
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let failure):
            if case .server(let statusCode, _) = failure.error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected server error")
            }
        }
    }
    
    func test_givenStubbedResponseWithDelay_whenGetCalled_thenReturnsAfterDelay() async {
        // Given
        struct User: Codable, Equatable {
            let id: Int
            let name: String
        }
        
        let expectedUser = User(id: 123, name: "John Doe")
        let delayDuration: TimeInterval = 0.1
        mockMercury.stubGet(path: "/users/123", response: expectedUser, delay: delayDuration)
        
        let startTime = Date()
        
        // When
        let result = await mockMercury.get(
            path: "/users/123",
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value, expectedUser)
            XCTAssertGreaterThanOrEqual(elapsedTime, delayDuration)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }
    
    // MARK: - Multiple Calls Tests
    
    func test_givenMockMercury_whenMultipleCallsMade_thenAllCallsAreRecorded() async {
        // Given
        struct User: Codable {
            let id: Int
            let name: String
        }
        
        mockMercury.stubGet(path: "/users/1", response: User(id: 1, name: "User 1"))
        mockMercury.stubGet(path: "/users/2", response: User(id: 2, name: "User 2"))
        mockMercury.stubPost(path: "/users", response: User(id: 3, name: "User 3"))
        
        // When
        _ = await mockMercury.get(path: "/users/1", headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        _ = await mockMercury.get(path: "/users/2", headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        _ = await mockMercury.post(path: "/users", body: User(id: 0, name: "New User"), headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 3)
        XCTAssertEqual(mockMercury.callCount(for: .GET, path: "/users/1"), 1)
        XCTAssertEqual(mockMercury.callCount(for: .GET, path: "/users/2"), 1)
        XCTAssertEqual(mockMercury.callCount(for: .POST, path: "/users"), 1)
        
        XCTAssertEqual(mockMercury.firstCall?.method, .GET)
        XCTAssertEqual(mockMercury.firstCall?.path, "/users/1")
        XCTAssertEqual(mockMercury.lastCall?.method, .POST)
        XCTAssertEqual(mockMercury.lastCall?.path, "/users")
    }
    
    // MARK: - Reset Functionality Tests
    
    func test_givenMockWithRecordedCalls_whenReset_thenCallsAndStubsAreCleared() async {
        // Given
        struct User: Codable {
            let id: Int
            let name: String
        }
        
        mockMercury.stubGet(path: "/users/123", response: User(id: 123, name: "John"))
        _ = await mockMercury.get(path: "/users/123", headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        
        XCTAssertEqual(mockMercury.callCount, 1)
        
        // When
        mockMercury.reset()
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 0)
        XCTAssertTrue(mockMercury.recordedCalls.isEmpty)
        
        // Verify stubs are also cleared by checking for default failure
        let result = await mockMercury.get(path: "/users/123", headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        switch result {
        case .success:
            XCTFail("Expected failure after reset")
        case .failure(let failure):
            if case .invalidURL = failure.error {
                // Expected - this is the default error when no stub is configured
            } else {
                XCTFail("Expected invalidURL error")
            }
        }
    }
    
    func test_givenMockWithData_whenClearRecordedCalls_thenOnlyCallsAreCleared() async {
        // Given
        struct User: Codable {
            let id: Int
            let name: String
        }
        
        mockMercury.stubGet(path: "/users/123", response: User(id: 123, name: "John"))
        _ = await mockMercury.get(path: "/users/123", headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        
        XCTAssertEqual(mockMercury.callCount, 1)
        
        // When
        mockMercury.clearRecordedCalls()
        
        // Then
        XCTAssertEqual(mockMercury.callCount, 0)
        XCTAssertTrue(mockMercury.recordedCalls.isEmpty)
        
        // Verify stubs are preserved
        let result = await mockMercury.get(path: "/users/123", headers: nil, query: nil, fragment: nil, cachePolicy: nil, responseType: User.self)
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.id, 123)
        case .failure:
            XCTFail("Expected success with preserved stub")
        }
    }
}

// MARK: - Service Layer Tests Example

/// Example of testing a service that uses Mercury
final class UserServiceTests: XCTestCase {
    
    private var mockMercury: MockMercury!
    private var userService: UserService!
    
    override func setUp() {
        super.setUp()
        mockMercury = Mercury.mock()
        userService = UserService(mercury: mockMercury)
    }
    
    override func tearDown() {
        userService = nil
        mockMercury = nil
        super.tearDown()
    }
    
    func test_givenValidUserId_whenFetchUser_thenReturnsUser() async {
        // Given
        let expectedUser = User(id: 123, name: "John Doe", email: "john@example.com")
        mockMercury.stubGet(path: "/users/123", response: expectedUser)
        
        // When
        let result = await userService.fetchUser(id: 123)
        
        // Then
        switch result {
        case .success(let user):
            XCTAssertEqual(user, expectedUser)
            XCTAssertTrue(mockMercury.wasCalled(method: .GET, path: "/users/123"))
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }
    
    func test_givenNetworkError_whenFetchUser_thenReturnsTransportError() async {
        // Given
        let networkError = MercuryError.transport(URLError(.notConnectedToInternet))
        mockMercury.stubFailure(method: .GET, path: "/users/123", error: networkError, responseType: User.self)
        
        // When
        let result = await userService.fetchUser(id: 123)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            // Try to cast to MercuryFailure if possible
            if let mercuryFailure = error as? MercuryFailure {
                switch mercuryFailure.error {
                case .transport:
                    // Success: got the expected transport error
                    break
                default:
                    XCTFail("Expected MercuryError.transport but got \(mercuryFailure.error)")
                }
            } else {
                XCTFail("Expected MercuryFailure but got \(error)")
            }
            XCTAssertTrue(mockMercury.wasCalled(method: .GET, path: "/users/123"))
        }
    }
}

// MARK: - Supporting Types for Examples

struct User: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
}

class UserService {
    private let mercury: MercuryProtocol
    
    init(mercury: MercuryProtocol) {
        self.mercury = mercury
    }
    
    func fetchUser(id: Int) async -> Result<User, Error> {
        let result = await mercury.get(
            path: "/users/\(id)",
            headers: nil,
            query: nil,
            fragment: nil,
            cachePolicy: nil,
            responseType: User.self
        )
        
        return result
            .map { $0.value }
            .mapError { $0 as Error }
    }
}

