<div align="center">

<img src="Images/mercury.png" alt="Mercury" width="300" />

> “Let Mercury go swiftly, bearing words not his, but heaven’s.”
>
> — Virgil, Aeneid 4.242–243

[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20iPadOS%2016%2B%20%7C%20macOS%2013%2B%20%7C%20watchOS%209%2B%20%7C%20tvOS%2016%2B%20%7C%20visionOS%201%2B-blue.svg?style=flat)](#requirements)
<br>

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat)](https://swift.org)
[![SPM ready](https://img.shields.io/badge/SPM-ready-brightgreen.svg?style=flat-square)](https://swift.org/package-manager/)
[![Coverage](https://img.shields.io/badge/Coverage-98.2%25-brightgreen.svg?style=flat)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>


Mercury is a lightweight and easy to use HTTP client for Swift that includes many quality of life features out of the box. It designed to remove networking boilerplate so you can focusing on building your app.

## <br><br> Features

- 🚀 **Modern Swift**: Built with Swift 5.9+ and async/await
- ⚡ **Cache Control**: Built-in URLRequest cache policy support
- 📦 **Auto-Encoding**: Automatic JSON encoding of `Encodable` request bodies
- 🎨 **Auto-Decoding**: Automatic JSON decoding to any `Decodable` response type
- 🔧 **Flexible URLs**: Smart URL parsing and construction
- 📝 **Request Signatures**: Unique signatures for caching and debugging
- 🔄 **Result-Based**: Structured error handling with `Result<MercurySuccess, MercuryFailure>`
- 🎯 **Protocol-Oriented**: Clean separation with `MercuryProtocol` for easy testing
- 🧪 **Mock Support**: Comprehensive `MockMercury` provided for testing

## <br><br> Installation
Add Mercury to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Mercury.git", from: "1.0.0")
]
```

## <br><br> Quick Start

### Setup

```swift
import Mercury

// Initialize with just a host
let client = Mercury(host: "https://api.example.com")

// Or with custom configuration
let client = Mercury(
    host: "https://api.example.com",
    port: 8080,
    defaultHeaders: [
        "Authorization": "Bearer \(token)",
        "Accept": "application/json"
    ]
)
```

Mercury intelligently parses various host formats:

```swift
Mercury(host: "https://api.example.com")           // Standard URL
Mercury(host: "api.example.com")                   // Defaults to HTTPS
Mercury(host: "https://localhost:3000")             // Custom protocol and port
Mercury(host: "https://api.example.com/api/v1")    // With base path
Mercury(host: "https://api.example.com:8443/v2")   // Custom port + base path
```

Mercury supports all standard HTTP methods:

```swift
await client.get(path: "/users")
await client.post(path: "/users", body: newUser)
await client.put(path: "/users/123", body: updatedUser)
await client.patch(path: "/users/123", body: partialUpdate)
await client.delete(path: "/users/123")
```

Build complex URLs with query parameters and fragments:

```swift
await client.get(
    path: "/users",
    queryItems: [
        "page": "2",
        "limit": "20",
        "sort": "name"
    ],
    fragment: "results"
)
// Results in: /users?page=2&limit=20&sort=name#results
```

### GET Example

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// GET request
let result = await client.get(
    path: "/users/123",
    responseType: User.self
)

switch result {
case .success(let success):
    print("User: \(success.value.name)")
    print("Status: \(success.httpResponse.statusCode)")
    
case .failure(let failure):
    print("Error: \(failure)")
    print("Error: \(failure.error)") // either work!
    print("Request: \(failure.requestSignature)")
}
```

### POST with Body Example

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

let newUser = CreateUserRequest(name: "John Doe", email: "john@example.com")

let result = await client.post(
    path: "/users",
    body: newUser,
    responseType: User.self
)
```

### Overrides
On a per request basis you can override the cache policy or headers.
Mercury will override any values it finds, or adds them before making the request.

```swift
let result = await client.get(
    path: "/users",
    headers: ["X-Custom-Header": "value"],
    query: ["page": "1", "limit": "20"],
    cachePolicy: .returnCacheDataElseLoad,
    responseType: [User].self
)
```

## <br> <br> Response Types

Mercury can decode responses to any `Decodable` type, or RAW data when needed:

### JSON Objects
```swift
struct ApiResponse: Codable {
    let data: [User]
    let pagination: Pagination
}

let result = await client.get(path: "/users", responseType: ApiResponse.self)
```

### Raw Data
```swift
let result = await client.get(path: "/image.png", responseType: Data.self)
```

## <br><br> Error Handling

Mercury provides comprehensive error information through `MercuryFailure` out of the box.

### Simple Error Logging
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
    // Output: "Decoding failed in 'User' for key 'userName': keyNotFound..."
}
```

### Complete Error Handling
Mercury surfaces meaningful errors with actionable data.

```swift
switch result {
case .failure(let failure):
    switch failure.error {
    case .server(let statusCode, let data):
        print("Server error \(statusCode)")
        if let errorBody = data, let message = String(data: errorBody, encoding: .utf8) {
            print("Server message: \(message)")
        }
        
    case .decodingFailed(let namespace, let key, _):
        print("Check your \(namespace) model - missing or wrong type for '\(key)'")
        
    case .transport(let error):
        print("Network issue: \(error.localizedDescription)")
        
    case .invalidURL:
        print("URL construction failed - check your path and query parameters")
        
    case .encoding(let error):
        print("Request body encoding failed: \(error)")
        
    case .invalidResponse:
        print("Server returned unexpected response format")
    }
    
    print("Request: \(failure.requestSignature)")
}
```

## <br><br> Request Signatures
Every request, whether Success or Failure, generates a unique SHA signature for caching and debugging:

```swift
switch result {
case .success(let success):
    print("Request signature: \(success.requestSignature)")
case .failure(let failure):
    print("Failed request: \(failure.requestSignature)")
}
```

## <br><br> Testing with MockMercury

Mercury includes `MockMercury` for comprehensive testing support:

```swift
import XCTest
@testable import Mercury

final class UserRepositoryTests: XCTestCase {
    
    func test_givenValidUser_whenCreateUser_thenReturnsSuccess() async {
        // Given
        let mock = MockMercury()
        let user = User(id: 1, name: "John", email: "john@example.com")
        
        mock.stubPost(
            path: "/users",
            response: user,
            statusCode: 201
        )
        
        let repository = UserRepository(client: mock)
        
        // When
        let result = await repository.createUser(name: "John", email: "john@example.com")
        
        // Then
        switch result {
        case .success(let success):
            XCTAssertEqual(success.value.name, "John")
            XCTAssertEqual(success.httpResponse.statusCode, 201)
        case .failure:
            XCTFail("Expected success")
        }
        
        // Verify the call was made
        XCTAssertTrue(mock.wasCalled(method: .POST, path: "/users"))
        XCTAssertEqual(mock.callCount, 1)
    }
    
    func test_givenServerError_whenCreateUser_thenReturnsFailure() async {
        // Given
        let mock = MockMercury()
        
        mock.stubFailure(
            method: .POST,
            path: "/users",
            error: .server(statusCode: 500, data: nil),
            responseType: User.self
        )
        
        let repository = UserRepository(client: mock)
        
        // When
        let result = await repository.createUser(name: "John", email: "john@example.com")
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let failure):
            if case .server(let statusCode, _) = failure.error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected server error")
            }
        }
    }
}
```

### Mock Capabilities

- ✅ **Method-Specific Stubbing**: Different responses for GET, POST, PUT, PATCH, DELETE
- ✅ **Call Recording**: Inspect all calls made including parameters
- ✅ **Flexible Responses**: Stub successes, failures, and custom delays
- ✅ **Query Verification**: Check specific method/path combinations were called
- ✅ **Parameter Inspection**: Verify headers, query parameters, and request bodies

### Mock Methods

```swift
let mock = MockMercury()

// Stub successful responses
mock.stubGet(path: "/users", response: users)
mock.stubPost(path: "/users", response: newUser, statusCode: 201)

// Stub failures
mock.stubFailure(method: .GET, path: "/users", error: .invalidURL, responseType: [User].self)

// Add delays for testing loading states
mock.stubGet(path: "/slow-endpoint", response: data, delay: 2.0)

// Reset for clean test state
mock.reset() // Clear both stubs and recorded calls
mock.clearStubs() // Clear only stubs
mock.clearRecordedCalls() // Clear only recorded calls

// Query recorded calls
print("Total calls: \(mock.callCount)")
print("GET /users called: \(mock.wasCalled(method: .GET, path: "/users"))")
print("Last call: \(mock.lastCall)")
```

## <br><br> License

Mercury is available under the MIT License. See the [LICENSE](./LICENSE) file for more details.

---

By Josh Gallant, Made with ❤️ for the Swift community
