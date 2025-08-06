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

# Mercury

An easy to use HTTP networking library for Swift with built-in JSON encoding/decoding, comprehensive error handling, and powerful testing capabilities.

## Features

- 🧬 **Type-aware:** Automatic encoding of request bodies and decoding of responses
- 🎯 **Result-based:** Clean error handling with Swift's Result type
- 📦 **Cache:** URLCache support ready to go
- 🔄 **Flexible:** Support for all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- ⚙️ **Configurable:** Custom headers, query parameters, caching policies, and more
- 🧪 **Testable:** Built-in mock with stubbing for comprehensive testing
  
## Installation

Add Mercury to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/joshgallantt/Mercury.git", from: "1.0.0")
]
```

Then add to your targets:

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

```swift
import Mercury

// Basic client
let client = Mercury(host: "https://api.example.com")

// Client with custom configuration
let client = Mercury(
    host: "https://api.example.com:8080/v1",
    defaultHeaders: [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer your-token"
    ],
    defaultCachePolicy: .reloadIgnoringLocalCacheData,
    cache: .isolated(
        memorySize: 4_000_000,  // 4MB
        diskSize: 10_000_000    // 10MB
    )
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
At the time of request you can override or add additional data:
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
    fragment: "section",  // URL fragment (#section)
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
    // Status Code: 200

    print("Headers: \(httpResponse.allHeaderFields)")
    // Headers: ["Content-Type": "application/json", "X-Request-ID": "abcd-efgh"]

    print("Request String: \(requestString)")
    // Request String: GET|https://api.example.com/v1/users/123|headers:accept:application/json&content-type:application/json

    print("Request Signature: \(signature)")
    // Request Signature: 2ca7f2481a7d7d4e31ad24bb3fbb13d79e531c55a5a44af8a1b7d1c8f2a3ea8a

case .failure:
    // Handle failure
}
```

### MercuryFailure

When a request fails, you receive a `MercuryFailure` containing:

```swift
switch result {
case .success:
    // Handle success

case .failure(let failure):
    let error = failure.error                     // The specific error type
    let httpResponse = failure.httpResponse       // HTTP response if available
    let requestString = failure.requestString     // Canonical request string
    let signature = failure.requestSignature      // Unique request signature (SHA256)

    print("Error: \(failure)")
    // Error: 404 Not Found

    print("Request String: \(requestString)")
    // Request String: GET|https://api.example.com/v1/users/999|headers:accept:application/json&content-type:application/json

    print("Request Signature: \(signature)")
    // Request Signature: 6d967252b5e347e612fb7caa0cbe0b6318d07db96902d2a2b7e1f804012debc2
}
```

### Request Signatures

Every request generates a deterministic **canonical string** and a unique **signature** for debugging, caching, and logging:

**The `requestString` includes:**

* HTTP method (e.g., `GET`, `POST`)
* Complete URL (with query and fragment, if present)
* Canonicalized (sorted) headers

**The `requestSignature` is:**

* A SHA256 hex digest of the canonical request string
* **Stable**: same request, same signature every time
* **Collision-resistant**: suitable for cache keys, request tracking, etc.

> [!TIP]
> These values are useful for cache keys, logging, or debugging.

## Cache Management

Mercury supports both **shared** and **isolated** cache strategies to optimize networking performance and resource usage. By default, each client uses `URLCache.shared`, but you can specify on per client with custom limits.

> [!TIP]
> Choose `.shared` for simplicity and interoperability, or `.isolated` for stricter cache boundaries and customizable storage.

```swift
import Mercury

let client = Mercury(
    host: "https://api.example.com",
    cache: .isolated(
        memorySize: 4_000_000,    // 4MB in-memory cache
        diskSize: 20_000_000      // 20MB on-disk cache
    )
)

// Clear this client's isolated cache.
client.clearCache()


Mercury.clearSharedURLCache()
```

> [!WARNING]
> Mercury.clearSharedURLCache() will clear the URLCache shared across the process, not just isolated to the Mercury or its client.

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
    // "Decoding failed in 'User' for key 'email': keyNotFound..."
    // "401 Unauthorized: Invalid API token"
    // "404 Not Found"
    // "Transport error: The Internet connection appears to be offline"
}
```

### Comprehensive Error Handling
If you need to handle specific errors, you can:

```swift
switch result {
case .success(let response):
    handleUser(response.value)
    
case .failure(let failure):
    switch failure.error {
    case .invalidURL:
        print("Invalid URL configuration")
        
    case .server(let statusCode, let data):
        print("Server error: \(statusCode)")
        if let data = data, let message = String(data: data, encoding: .utf8) {
            print("Server message: \(message)")
        }
        
    case .invalidResponse:
        print("Received invalid response from server")
        
    case .transport(let error):
        print("Network error: \(error.localizedDescription)")
        
    case .encoding(let error):
        print("Failed to encode request: \(error)")
        
    case .decoding(let namespace, let key, let error):
        print("Failed to decode \(namespace).\(key): \(error)")
    }
}
```

## Testing with MockMercury

Mercury includes a powerful mock for comprehensive testing:

### Basic Test Setup

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

class UserService {
    private let client: MercuryProtocol
    
    init(client: MercuryProtocol) {
        self.client = client
    }
    
    func fetchUser(id: Int) async -> User? {
        let result = await client.get(
            path: "/users/\(id)",
            responseType: User.self
        )
        
        switch result {
        case .success(let response):
            return response.value
        case .failure:
            return nil
        }
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

By Josh Gallant, Made with ❤️ for the Swift community
