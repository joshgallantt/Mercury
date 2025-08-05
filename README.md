<div align="center">

<img src="Images/mercury.png" alt="Mercury" width="300" />

> “Let Mercury go swiftly, bearing words not his, but heaven’s.”
>
> — Virgil, Aeneid 4.242–243

[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20iPadOS%2016%2B%20%7C%20macOS%2013%2B%20%7C%20watchOS%209%2B%20%7C%20tvOS%2016%2B%20%7C%20visionOS%201%2B-blue.svg?style=flat)](#requirements)
<br>

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat)](https://swift.org)
[![SPM ready](https://img.shields.io/badge/SPM-ready-brightgreen.svg?style=flat-square)](https://swift.org/package-manager/)
[![Coverage](https://img.shields.io/badge/Coverage-98%25-brightgreen.svg?style=flat)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>

# Mercury

A easy to use type-aware HTTP networking library for Swift with built-in JSON encoding/decoding, comprehensive error handling, and powerful testing capabilities.

## Features

- 🧬 **Type-aware:** Automatic encoding of request bodies and decoding of responses
- 🎯 **Result-based:** Clean error handling with Swift's Result type
- 🔄 **Flexible:** Support for all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- ⚙️ **Configurable:** Custom headers, query parameters, caching policies, and more
- 🧪 **Testable:** Built-in mock with stubbing for comprehensive testing
  
## Installation

Add Mercury to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Mercury.git", from: "1.0.0")
]
```

## Quick Start

### 1. Create a Client

```swift
import Mercury

// Basic client
let client = Mercury(host: "https://api.example.com")

// Client with custom configuration
let client = Mercury(
    host: "https://api.example.com",
    port: 8080,
    defaultHeaders: [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer your-token"
    ],
    defaultCachePolicy: .reloadIgnoringLocalCacheData
)
```

### 2. Make Requests

#### GET Request

```swift
struct User: Decodable {
    let id: Int
    let name: String
    let email: String
}

let result = await client.get(
    path: "/users/123",
    responseType: User.self
)

switch result {
case .success(let response):
    print("User: \(response.value.name)")
case .failure(let error):
    print("Error: \(error)")
}
```

#### POST Request with Body

```swift
struct CreateUserRequest: Encodable {
    let name: String
    let email: String
}

struct CreateUserResponse: Decodable {
    let id: Int
    let name: String
    let email: String
    let createdAt: String
}

let newUser = CreateUserRequest(name: "John Doe", email: "john@example.com")

let result = await client.post(
    path: "/users",
    body: newUser,
    responseType: CreateUserResponse.self
)

switch result {
case .success(let response):
    print("Created user with ID: \(response.value.id)")
case .failure(let error):
    print("Failed to create user: \(error)")
}
```

### 3. Working with Nested Types

```swift
struct UserProfile: Decodable {
    let user: User
    let preferences: UserPreferences
    let addresses: [Address]
}

struct UserPreferences: Decodable {
    let theme: String
    let notifications: Bool
    let language: String
}

struct Address: Decodable {
    let id: Int
    let street: String
    let city: String
    let country: String
    let isDefault: Bool
}

let result = await client.get(
    path: "/users/123/profile",
    responseType: UserProfile.self
)

switch result {
case .success(let response):
    let profile = response.value
    print("User: \(profile.user.name)")
    print("Addresses: \(profile.addresses.count)")
    print("Theme: \(profile.preferences.theme)")
case .failure(let error):
    print("Error loading profile: \(error)")
}
```

### 4. Decoding Raw Data (Images, Files)

```swift
// For binary data like images
let result = await client.get(
    path: "/users/123/avatar",
    responseType: Data.self
)

switch result {
case .success(let response):
    let imageData = response.value
    let image = UIImage(data: imageData)
    // Use the image...
case .failure(let error):
    print("Failed to load avatar: \(error)")
}

// For plain text responses
let result = await client.get(
    path: "/health",
    responseType: String.self
)

switch result {
case .success(let response):
    print("Health status: \(response.value)")
case .failure(let error):
    print("Health check failed: \(error)")
}
```

### 5. Per Request Overrides
You can override or add aditional values at the time of request:
```swift
let result = await client.get(
    path: "/users/123",
    headers: [
        "X-Custom-Header": "custom-value",
        "Accept-Language": "en-US"
    ],
    query: [
        "include": "profile,preferences",
        "format": "detailed"
    ],
    cachePolicy: .reloadIgnoringLocalCacheData,
    responseType: User.self
)
```

## Response Types

### MercurySuccess

When a request succeeds, you receive a `MercurySuccess<T>` containing:

```swift
let result = await client.get(path: "/users/123", responseType: User.self)

switch result {
case .success(let success):
    let user = success.value                      // The decoded response
    let httpResponse = success.httpResponse       // HTTP metadata
    let requestString = success.requestString     // Canonical request string
    let signature = success.requestSignature      // Unique request signature (SHA256)

    print("Status Code: \(httpResponse.statusCode)")
    print("Headers: \(httpResponse.allHeaderFields)")
    print("Request String: \(requestString)")
    print("Request Signature: \(signature)")
}
```

### MercuryFailure

When a request fails, you receive a `MercuryFailure` containing:

```swift
switch result {
case .failure(let failure):
    let error = failure.error                     // The specific error type
    let requestString = failure.requestString     // Canonical request string
    let signature = failure.requestSignature      // Unique request signature (SHA256)

    print("Error: \(failure.description)")
    print("Request String: \(requestString)")
    print("Request Signature: \(signature)")
}
```

### Request Signatures

Every request generates a deterministic **canonical string** and a unique **signature** for debugging, caching, and logging:

```swift
let result = await client.get(path: "/users/123", responseType: User.self)

switch result {
case .success(let response):
    print("Request string: \(response.requestString)")
    // Example: "GET|https://api.example.com/users/123|headers:accept:application/json"
    
    print("Request signature: \(response.requestSignature)")
    // Example: "cf9926cb53728d1111a042f03eb64cba298bdd2df0e0909a9f39c3523cfe7271"
    
case .failure(let failure):
    print("Failed request string: \(failure.requestString)")
    print("Failed request signature: \(failure.requestSignature)")
}
```

**The `requestString` includes:**

* HTTP method (e.g., `GET`, `POST`)
* Complete URL (with query and fragment, if present)
* Canonicalized, (sorted) headers.

**The `requestSignature` is:**

* A SHA256 hex digest of the canonical request string
* **Stable**: same request, same signature every time
* **Collision-resistant**: suitable for cache keys, request tracking, etc.

**Use these for:**

* **Debugging**: Identify exactly which request succeeded or failed
* **Caching**: Use the request signature as a cache key
* **Logging**: Track unique request patterns
* **Testing**: Verify that the exact request was made (or failed)

## Error Handling

### Simple Error Handling (Common Case)

Did you forget to make something nullable? Mercury pinpoints exactly what went wrong:

```swift
let result = await client.get(
    path: "/users",
    responseType: User.self
)

switch result {
case .success(let success):
    print("Got user: \(success.value.name)")
    
case .failure(let failure):
    // Simple, descriptive error message
    print("Request failed: \(failure)")
    // Examples:
    // "Decoding failed in 'User' for key 'userName': keyNotFound..."
    // "401 Unauthorized: Invalid API token"
    // "404 Not Found"
    // "Transport error: The Internet connection appears to be offline"
}
```

### Comprehensive Error Handling

```swift
switch result {
case .success(let response):
    handleUser(response.value)
    
case .failure(let failure):
    switch failure.error {
    case .invalidURL:
        print("Invalid URL configuration")
        
    case .server:
        // Mercury provides descriptive server error messages
        print("Server error: \(failure)")
        // Examples:
        // "401 Unauthorized: Invalid API token"
        // "404 Not Found"
        // "422 Unprocessable Entity: Email already exists"
        
    case .invalidResponse:
        print("Received invalid response from server")
        
    case .transport:
        print("Network error: \(failure)")
        
    case .encoding:
        print("Failed to encode request: \(failure)")
        
    case .decoding:
        print("Data format error: \(failure)")
    }
}
```

## Testing with MockMercury

Mercury includes a powerful mock for comprehensive testing:

### Basic Test Setup

```swift
import XCTest
@testable import Mercury

final class UserServiceTests: XCTestCase {
    private var mockClient: MockMercury!
    private var userService: UserService!
    
    override func setUp() {
        super.setUp()
        mockClient = MockMercury()
        userService = UserService(client: mockClient)
    }
    
    override func tearDown() {
        mockClient = nil
        userService = nil
        super.tearDown()
    }
}

class UserService {
    private let client: MercuryProtocol
    
    init(client: MercuryProtocol) {
        self.client = client
    }
    
    func fetchUser(id: Int) async -> Result<User, MercuryFailure> {
        await client.get(path: "/users/\(id)", responseType: User.self)
    }
}
```

### Stubbing Successful Responses

```swift
func test_givenValidUserId_whenFetchUser_thenReturnsUser() async {
    // Given
    let expectedUser = User(id: 123, name: "John Doe", email: "john@example.com")
    mockClient.stubGet(path: "/users/123", response: expectedUser)
    
    // When
    let result = await userService.fetchUser(id: 123)
    
    // Then
    switch result {
    case .success(let response):
        XCTAssertEqual(response.value.id, 123)
        XCTAssertEqual(response.value.name, "John Doe")
    case .failure:
        XCTFail("Expected success")
    }
}
```

### Stubbing Failures

```swift
func test_givenServerError_whenFetchUser_thenReturnsFailure() async {
    // Given
    mockClient.stubFailure(
        method: .GET,
        path: "/users/123",
        error: .server(statusCode: 404, data: nil),
        responseType: User.self
    )
    
    // When
    let result = await userService.fetchUser(id: 123)
    
    // Then
    switch result {
    case .success:
        XCTFail("Expected failure")
    case .failure(let failure):
        if case .server(let statusCode, _) = failure.error {
            XCTAssertEqual(statusCode, 404)
        } else {
            XCTFail("Expected server error")
        }
    }
}
```

### Verifying Calls

```swift
func test_givenUserId_whenFetchUser_thenMakesCorrectRequest() async {
    // Given
    let user = User(id: 123, name: "John Doe", email: "john@example.com")
    mockClient.stubGet(path: "/users/123", response: user)
    
    // When
    _ = await userService.fetchUser(id: 123)
    
    // Then
    XCTAssertEqual(mockClient.callCount, 1)
    XCTAssertTrue(mockClient.wasCalled(method: .GET, path: "/users/123"))
    
    let lastCall = mockClient.lastCall
    XCTAssertEqual(lastCall?.method, .GET)
    XCTAssertEqual(lastCall?.path, "/users/123")
    XCTAssertFalse(lastCall?.hasBody ?? true)
}
```

### Testing with Delays

```swift
func test_givenSlowNetwork_whenFetchUser_thenHandlesDelay() async {
    // Given
    let user = User(id: 123, name: "John Doe", email: "john@example.com")
    mockClient.stubGet(path: "/users/123", response: user, delay: 2.0)
    
    let startTime = Date()
    
    // When
    _ = await userService.fetchUser(id: 123)
    
    // Then
    let elapsed = Date().timeIntervalSince(startTime)
    XCTAssertGreaterThanOrEqual(elapsed, 2.0)
}
```

### Testing POST Requests

```swift
func test_givenUserData_whenCreateUser_thenMakesCorrectRequest() async {
    // Given
    let newUser = CreateUserRequest(name: "Jane Doe", email: "jane@example.com")
    let createdUser = CreateUserResponse(id: 456, name: "Jane Doe", email: "jane@example.com", createdAt: "2023-01-01")
    mockClient.stubPost(path: "/users", response: createdUser, statusCode: 201)
    
    // When
    _ = await userService.createUser(newUser)
    
    // Then
    XCTAssertTrue(mockClient.wasCalled(method: .POST, path: "/users"))
    
    let lastCall = mockClient.lastCall
    XCTAssertTrue(lastCall?.hasBody ?? false)
}
```

### Mock Management

```swift
func test_mockCleanup() {
    // Setup multiple stubs
    mockClient.stubGet(path: "/users/1", response: User(id: 1, name: "User 1", email: "user1@example.com"))
    mockClient.stubGet(path: "/users/2", response: User(id: 2, name: "User 2", email: "user2@example.com"))
    
    // Clear specific data
    mockClient.clearRecordedCalls()  // Keeps stubs, clears call history
    mockClient.clearStubs()          // Keeps calls, clears stubs
    mockClient.reset()               // Clears everything
    
    XCTAssertEqual(mockClient.callCount, 0)
}
```

## License

Mercury is available under the MIT License. See the [LICENSE](./LICENSE) file for more details.

---

By Josh Gallant, Made with ❤️ for the Swift community
