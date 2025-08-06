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

An easy to use HTTP networking library for Swift with built-in JSON encoding/decoding, comprehensive error handling, and powerful testing capabilities.

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Making Requests](#making-requests)
5. [Handling Responses](#handling-responses)
6. [Cache Management](#cache-management)
7. [Error Handling](#error-handling)
8. [Testing](#testing)
9. [License](#license)

## Features

* **Type-aware:** Codable encoding/decoding for request and response
* **Result-based:** Uses Swift’s `Result` type for clean error handling
* **Cache:** Ready-to-use with `URLCache`
* **Flexible:** Supports all HTTP methods (GET, POST, PUT, PATCH, DELETE)
* **Configurable:** Custom headers, query parameters, caching, and more
* **Testable:** Built-in mocking and stubbing for reliable tests

## Installation

Add Mercury to your project with [Swift Package Manager](https://swift.org/package-manager/):

```swift
dependencies: [
    .package(url: "https://github.com/joshgallantt/Mercury.git", from: "1.0.0")
]
```

Then add `"Mercury"` to your targets:

```swift
.target(
    name: "YourApp",
    dependencies: ["Mercury"]
),
.testTarget(
    name: "YourAppTests",
    dependencies: ["Mercury", "MercuryTesting"]
)
```

## Quick Start

### 1. Create a Client

Import Mercury:

```swift
import Mercury
```

Create a basic client:

```swift
let client = Mercury(host: "https://api.example.com")
```

Or configure with options:

```swift
let client = Mercury(
    host: "https://api.example.com:8080/v1",
    defaultHeaders: [
        "Accept": "application/json",
        "Authorization": "Bearer your-token"
    ],
    defaultCachePolicy: .reloadIgnoringLocalCacheData,
    cache: .isolated(
        memorySize: 4_000_000, // 4MB in-memory
        diskSize: 10_000_000   // 10MB disk
    )
)
```

## Making Requests

### GET Request

Define your response model:

```swift
struct User: Decodable {
    let id: Int
    let name: String
    let email: String
}
```

Make the request:

```swift
let result = await client.get(
    path: "/users/123",
    responseType: User.self
)
```

Handle the response:

```swift
switch result {
case .success(let response):
    print("User: \(response.value.name)")
case .failure(let error):
    print("Error: \(error)")
}
```

### POST Request (with Body)

Define your models:

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
```

Make the POST:

```swift
let newUser = CreateUserRequest(name: "John Doe", email: "john@example.com")

let result = await client.post(
    path: "/users",
    body: newUser,
    responseType: CreateUserResponse.self
)
```

### Handling Nested Types

You can decode deeply nested objects just by specifying the type:

```swift
struct UserProfile: Decodable {
    let user: User
    let preferences: UserPreferences
    let addresses: [Address]
}
```

```swift
let result = await client.get(
    path: "/users/123/profile",
    responseType: UserProfile.self
)
```

### Decoding Raw Data (Images, Files)

**Binary data example:**

```swift
let result = await client.get(
    path: "/users/123/avatar",
    responseType: Data.self
)
```

**Text response example:**

```swift
let result = await client.get(
    path: "/health",
    responseType: String.self
)
```

### Per Request Overrides

You can override headers, add new ones, or specify a custom cache policy for each request:

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
    fragment: "section",
    cachePolicy: .reloadIgnoringLocalCacheData,
    responseType: User.self
)
```

## Handling Responses

Each request returns a `Result` with:

* `MercurySuccess<T>` on success
* `MercuryFailure` on failure

**On success:**

```swift
case .success(let success):
    let value = success.value
    let httpResponse = success.httpResponse
    let requestString = success.requestString
    let signature = success.requestSignature

    print("Status Code: \(httpResponse.statusCode)")
    // Status Code: 200

    print("Headers: \(httpResponse.allHeaderFields)")
    // Headers: ["Content-Type": "application/json", "X-Request-ID": "abcd-efgh"]

    print("Request String: \(requestString)")
    // Request String: GET|https://api.example.com/v1/users/123|headers:accept:application/json&content-type:application/json

    print("Request Signature: \(signature)")
    // Request Signature: 2ca7f2481a7d7d4e31ad24bb3fbb13d79e531c55a5a44af8a1b7d1c8f2a3ea8a
```

**On failure:**

```swift
case .failure(let failure):
    print("Error: \(failure)")
    // Console: Error: 404 Not Found

    print("Request String: \(failure.requestString)")
    // Request String: GET|https://api.example.com/v1/users/999|headers:accept:application/json&content-type:application/json

    print("Request Signature: \(failure.requestSignature)")
    // Request Signature: 6d967252b5e347e612fb7caa0cbe0b6318d07db96902d2a2b7e1f804012debc2
```
> [!TIP]
> Request signatures are deterministic SHA256 hashes, great for debugging, caching, and logging.

## Cache Management

Mercury supports two caching strategies:

* `.shared` (default): uses `URLCache.shared`
* `.isolated`: your own limits per client

**Example:**

```swift
let client = Mercury(
    host: "https://api.example.com",
    cache: .isolated(memorySize: 4_000_000, diskSize: 20_000_000)
)

client.clearCache() // Clears this client’s cache only
```

**To clear all shared cache:**

```swift
Mercury.clearSharedURLCache()
```

> [!WARNING]
> Mercury.clearSharedURLCache() clears the global shared URLCache for your process, this includes any URLSession cache outside of Mercury or its clients.

## Error Handling

Simple error handling:

```swift
switch result {
case .success(let success):
    print("Got user: \(success.value.name)")
    // Console: Got user: John Doe

case .failure(let failure):
    print("Request failed: \(failure)")
    /*
    // Console example outputs:
    Request failed: Decoding failed in 'User' for key 'email'
    Request failed: 401 Unauthorized: Invalid API token
    Request failed: 404 Not Found
    Request failed: Transport error: Lost Connection
    */
}
```

Handle specific errors if you need more control:

```swift
switch failure.error {
case .invalidURL:
    print("Invalid URL configuration")
case .server(let statusCode, let data):
    print("Server error: \(statusCode)")
case .invalidResponse:
    print("Invalid response from server")
case .transport(let error):
    print("Network error: \(error.localizedDescription)")
case .encoding(let error):
    print("Encoding failed: \(error)")
case .decoding(let namespace, let key, let error):
    print("Failed to decode \(namespace).\(key): \(error)")
}
```

## Testing

Mercury ships with a mock client for robust, fully isolated unit tests.

### Basic Setup

```swift
import XCTest
import Mercury
import MercuryTesting

final class UserServiceTests: XCTestCase {
    private var mockClient: MockMercury!
    private var userService: UserService!

    override func setUp() {
        super.setUp()
        mockClient = MockMercury()
        userService = UserService(client: mockClient)
    }

    override func tearDown() {
        mockClient.reset()
        mockClient = nil
        userService = nil
        super.tearDown()
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
    let user = await userService.fetchUser(id: 123)

    // Then
    XCTAssertEqual(user?.id, 123)
    XCTAssertEqual(user?.name, "John Doe")
    XCTAssertTrue(mockClient.wasCalled(method: .GET, path: "/users/123"))
}
```

### Stubbing Failures

```swift
func test_givenServerError_whenFetchUser_thenReturnsNil() async {
    // Given
    mockClient.stubFailure(
        method: .GET,
        path: "/users/123",
        error: .server(statusCode: 404, data: nil),
        responseType: User.self
    )

    // When
    let user = await userService.fetchUser(id: 123)

    // Then
    XCTAssertNil(user)
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
    XCTAssertEqual(mockClient.callCount(for: .GET, path: "/users/123"), 1)
    XCTAssertTrue(mockClient.wasCalled(method: .GET, path: "/users/123"))
    let calls = mockClient.recordedCalls
    XCTAssertEqual(calls.count, 1)
    XCTAssertEqual(calls[0].method, .GET)
    XCTAssertEqual(calls[0].path, "/users/123")
    XCTAssertFalse(calls[0].hasBody)
}
```

## License

Mercury is available under the MIT License. See the [LICENSE](./LICENSE) file for more details.

---

<div align="center">
  By Josh Gallant  
  Made with ❤️ for the Swift community
</div>
