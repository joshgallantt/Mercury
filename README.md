<div align="center">

<img src="Images/mercury.png" alt="Mercury" width="300" />

> “Let Mercury go swiftly, bearing words not his, but heaven’s.”
>
> — Virgil, Aeneid 4.242–243

[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20iPadOS%2016%2B%20%7C%20macOS%2013%2B%20%7C%20watchOS%209%2B%20%7C%20tvOS%2016%2B%20%7C%20visionOS%201%2B-blue.svg?style=flat)](#requirements)
<br>

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat)](https://swift.org)
[![SPM ready](https://img.shields.io/badge/SPM-ready-brightgreen.svg?style=flat-square)](https://swift.org/package-manager/)
[![Coverage](https://img.shields.io/badge/Coverage-98.5%25-brightgreen.svg?style=flat)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>


A modern, type-safe HTTP client for Swift built with Swift Concurrency. Mercury provides a clean, protocol-based API that's perfect for dependency injection and testing.

## Features

- ✅ **Swift Concurrency**: Built from the ground up with async/await
- ✅ **Protocol-Based**: Easy dependency injection and testing with `MercuryProtocol`
- ✅ **Flexible Payloads**: Support for raw `Data`, `Encodable` objects, and empty bodies
- ✅ **Customizable Headers**: Per-request and default header support
- ✅ **Cache Control**: Fine-grained caching policy control
- ✅ **Query Parameters**: Built-in query string and URL fragment support
- ✅ **Mock Support**: Comprehensive mocking for unit tests
- ✅ **Error Handling**: Detailed error types for robust error handling

## Installation

### Swift Package Manager

Add Mercury to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/joshgallantt/Mercury.git", from: "1.0.0")
]
```

## Quick Start

```swift
import Mercury

// Initialize the client
let client = Mercury(host: "https://api.example.com")

// Make a simple GET request
let result = await client.get("/users")

switch result {
case .success(let response):
    // Handle successful response
    let data = response.data
    let statusCode = response.response.statusCode
case .failure(let error):
    // Handle error
    print("Request failed: \(error)")
}
```

## API Overview

### HTTP Methods

Mercury supports all standard HTTP methods:

```swift
// GET request
await client.get("/users")

// POST with raw data
await client.post("/users", data: userData)

// POST with Encodable object
await client.post("/users", body: newUser)

// PUT request
await client.put("/users/123", body: updatedUser)

// PATCH request
await client.patch("/users/123", body: partialUpdate)

// DELETE request
await client.delete("/users/123")
```

### Payload Options

Mercury provides flexible payload handling for different use cases:

#### 1. Raw Data Payloads

Perfect for when you have pre-encoded data or need full control over the request body:

```swift
let jsonData = """
{
    "name": "John Doe",
    "email": "john@example.com"
}
""".data(using: .utf8)!

let result = await client.post("/users", data: jsonData)
```

#### 2. Encodable Objects

Automatically encode Swift types to JSON:

```swift
struct User: Encodable {
    let name: String
    let email: String
}

let newUser = User(name: "John Doe", email: "john@example.com")
let result = await client.post("/users", body: newUser)
```

#### 3. Custom Encoding

Use custom encoders for specialized formatting:

```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.keyEncodingStrategy = .convertToSnakeCase

let result = await client.post(
    "/users",
    body: newUser,
    encoder: encoder
)
```

#### 4. Empty Bodies

For requests that don't require a body:

```swift
// All methods support nil/empty bodies
await client.get("/users")
await client.delete("/users/123")  // DELETE with no body
await client.post("/users/123/activate")  // POST with no body
```

### Headers and Customization

#### Default Headers

Set headers that apply to all requests:

```swift
let client = Mercury(
    host: "https://api.example.com",
    defaultHeaders: [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer \(token)"
    ]
)
```

#### Per-Request Headers

Override or add headers for specific requests:

```swift
await client.get(
    "/users",
    headers: [
        "X-Request-ID": UUID().uuidString,
        "Accept": "application/vnd.api+json"  // Overrides default
    ]
)
```

#### Header Merging

Per-request headers are merged with default headers, with per-request headers taking precedence:

```swift
// Default headers: ["Accept": "application/json", "Authorization": "Bearer token"]
// Request headers: ["Accept": "text/plain", "X-Custom": "value"]
// Final headers: ["Accept": "text/plain", "Authorization": "Bearer token", "X-Custom": "value"]
```

### Cache Policies

Control caching behavior at the client and request level:

#### Default Cache Policy

Set a default policy for all requests:

```swift
let client = Mercury(
    host: "https://api.example.com",
    defaultCachePolicy: .reloadIgnoringLocalCacheData
)
```

#### Per-Request Cache Policy

Override caching for specific requests:

```swift
// Use cache if available, otherwise load from network
await client.get("/users", cachePolicy: .returnCacheDataElseLoad)

// Always reload from network
await client.get("/users", cachePolicy: .reloadIgnoringLocalCacheData)

// Only use cached data
await client.get("/users", cachePolicy: .returnCacheDataDontLoad)
```

### Query Parameters and URL Fragments

Build complex URLs with query parameters and fragments:

```swift
await client.get(
    "/users",
    queryItems: [
        "page": "2",
        "limit": "20",
        "sort": "name"
    ],
    fragment: "results"
)
// Results in: /users?page=2&limit=20&sort=name#results
```

### Advanced Configuration

#### Custom Ports and Base Paths

```swift
// With custom port
let client = Mercury(host: "https://api.example.com:8443")

// With base path
let client = Mercury(host: "https://api.example.com/v2")

// Both
let client = Mercury(host: "https://api.example.com:8443/api/v2")
```

#### Host Parsing

Mercury intelligently parses various host formats:

```swift
Mercury(host: "https://api.example.com")           // Standard URL
Mercury(host: "api.example.com")                   // Defaults to HTTPS
Mercury(host: "http://localhost:3000")             // Custom protocol and port
Mercury(host: "https://api.example.com/api/v1")    // With base path
```

## Error Handling

Mercury provides detailed error information through the `MercuryError` enum:

```swift
let result = await client.get("/users")

switch result {
case .success(let response):
    // Handle success
    break
case .failure(let error):
    switch error {
    case .invalidURL:
        print("The URL could not be constructed")
    case .server(let statusCode, let data):
        print("Server error: \(statusCode)")
        if let data = data, let message = String(data: data, encoding: .utf8) {
            print("Error details: \(message)")
        }
    case .invalidResponse:
        print("Response was not a valid HTTP response")
    case .transport(let error):
        print("Network error: \(error.localizedDescription)")
    case .encoding(let error):
        print("Failed to encode request body: \(error.localizedDescription)")
    }
}
```

## Testing

Mercury includes `MockMercury` for comprehensive testing support:

```swift
import XCTest
@testable import Mercury

final class UserRepositoryTests: XCTestCase {
    
    func test_givenValidUser_whenCreateUser_thenReturnsSuccess() async throws {
        // Given
        let mock = MockMercury()
        let expectedResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )!
        
        await mock.setPostResult(.success(
            MercurySuccess(data: Data(), response: expectedResponse)
        ))
        
        let repository = UserRepository(client: mock)
        
        // When
        let result = await repository.createUser(name: "John", email: "john@example.com")
        
        // Then
        XCTAssertTrue(result.isSuccess)
        
        let calls = await mock.recordedCalls
        XCTAssertEqual(calls.count, 1)
        
        if case .postEncodable(let path, _, _, _) = calls.first {
            XCTAssertEqual(path, "/users")
        } else {
            XCTFail("Expected postEncodable call")
        }
    }
}
```

### Mock Capabilities

- ✅ **Stub Results**: Set custom responses for each HTTP method
- ✅ **Call Recording**: Inspect all calls made to the mock
- ✅ **Method-Specific**: Different stubs for GET, POST, PUT, PATCH, DELETE
- ✅ **Parameter Capture**: Verify paths, headers, query items, and fragments


## Architecture

Mercury follows Clean Architecture principles and SOLID design patterns:

- **Protocol-Based**: `MercuryProtocol` enables easy dependency injection
- **Testable**: Built-in mocking support for comprehensive testing
- **Concurrent**: Safe for use with Swift Concurrency (`Sendable` conformance)
- **Type-Safe**: Leverages Swift's type system for compile-time safety

## License

Mercury is available under the MIT License. See the [LICENSE](./LICENSE) file for more details.

---

By Josh Gallant, Made with ❤️ for the Swift community
