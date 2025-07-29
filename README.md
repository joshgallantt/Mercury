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


Mercury is a lightweight, testable HTTP client that makes Swift networking ergonomic, predictable, and concurrency-safe by default. With built-in support for clean URL construction, customizable headers, and structured error handling, it lets you focus on your app logic - not request plumbing.

## <br><br> Features

- ✅ **Swift Concurrency**: Built from the ground up with async/await
- ✅ **Protocol-Based**: Easy dependency injection and testing with `MercuryProtocol`
- ✅ **Flexible Payloads**: Support for raw `Data`, `Encodable` objects, and empty bodies
- ✅ **Customizable Headers**: Per-request and default header support
- ✅ **Cache Control**: Fine-grained caching policy control
- ✅ **Query Parameters**: Built-in query string and URL fragment support
- ✅ **Mock Support**: Comprehensive mocking for unit tests
- ✅ **Error Handling**: Detailed error types for robust error handling
- ✅ **Deterministic Signatures**: Every request returns a stable, content-aware `requestSignature`

## <br><br> Installation

Add Mercury to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/joshgallantt/Mercury.git", from: "1.0.0")
]
```

## <br><br> Quick Start

Basic usage:

```swift
import Mercury

let client = Mercury(host: "https://api.example.com")

let result = await client.get("/users")

switch result {
case .success(let success):
    let data = success.data
    let statusCode = success.response.statusCode
    let signature = success.requestSignature
    print("✅ Success [\(statusCode)] with signature: \(signature)")
    
case .failure(let failure):
    let error = failure.error
    let signature = failure.requestSignature
    print("❌ Failure [\(error)] for request: \(signature)")
}
```

Mercury intelligently parses various host formats:

```swift
Mercury(host: "https://api.example.com")           // Standard URL
Mercury(host: "api.example.com")                   // Defaults to HTTPS
Mercury(host: "http://localhost:3000")             // Custom protocol and port
Mercury(host: "https://api.example.com/api/v1")    // With base path
Mercury(host: "https://api.example.com:8443/v2")   // Custom port + base path
```

Mercury supports all standard HTTP methods:

```swift
await client.get("/users")
await client.post("/users", body: newUser)
await client.put("/users/123", body: updatedUser)
await client.patch("/users/123", body: partialUpdate)
await client.delete("/users/123")
```

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

## <br><br> Payloads

### Raw Data Payloads
Perfect for when you have pre-encoded data or need full control:

```swift
let jsonData = """
{
    "name": "John Doe",
    "email": "john@example.com"
}
""".data(using: .utf8)!

let result = await client.post("/users", data: jsonData)
```

### Encodable Objects
Automatically encode Swift types to JSON:

```swift
struct User: Encodable {
    let name: String
    let email: String
}

let newUser = User(name: "John Doe", email: "john@example.com")
let result = await client.post("/users", body: newUser)
```

### Custom Encoding
Use custom encoders for specialized formatting:

```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.keyEncodingStrategy = .convertToSnakeCase

let result = await client.post("/users", body: newUser, encoder: encoder)
```

## <br><br> Headers

### Default Headers
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

### Per-Request Headers
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

## <br><br> Cache Policies

### Default Cache Policy
Set a default policy for all requests:

```swift
let client = Mercury(
    host: "https://api.example.com",
    defaultCachePolicy: .reloadIgnoringLocalCacheData
)
```

### Per-Request Cache Policy Overrides
Override caching for specific requests:

```swift
// Use cache if available, otherwise load from network
await client.get("/users", cachePolicy: .returnCacheDataElseLoad)

// Always reload from network
await client.get("/users", cachePolicy: .reloadIgnoringLocalCacheData)

// Only use cached data
await client.get("/users", cachePolicy: .returnCacheDataDontLoad)
```

## <br><br> Responses

Every network request returns a `Result<MercurySuccess, MercuryFailure>`.

### MercurySuccess

```swift
struct MercurySuccess {
    let data: Data
    let response: HTTPURLResponse
    let requestSignature: String
}
```

- `data`: The raw response body
- `response`: The HTTP response metadata
- `requestSignature`: A **deterministic hash** representing the full request

### MercuryFailure

```swift
struct MercuryFailure: Error {
    let error: MercuryError
    let requestSignature: String
}
```

- `error`: One of the structured `MercuryError` cases
- `requestSignature`: Same unique hash - available even on failure

### What is `requestSignature`?

`requestSignature` is a **unique, content-aware hash** that Mercury generates for every request. It's based on the complete request structure (method, URL, headers, body) and is **guaranteed to be deterministic** - the same request will always produce the same signature.

**Use cases:**
- **Cache invalidation**: Target specific cached requests
- **Request deduplication**: Detect duplicate or replayed requests  
- **Logging & debugging**: Track requests across your app
- **Analytics**: Group related network calls

## <br><br> Error Handling

```swift
enum MercuryError: Error {
    case invalidURL
    case server(statusCode: Int, data: Data?)
    case invalidResponse
    case transport(Error)
    case encoding(Error)
}
```

| Case | Description |
|------|-------------|
| `invalidURL` | Failed to build a valid URL |
| `server(_, data?)` | Non-2xx status code, optional response body available |
| `invalidResponse` | Response wasn't an `HTTPURLResponse` |
| `transport(Error)` | Network issue (no internet, timeout, SSL error) |
| `encoding(Error)` | Failed to encode `Encodable` body as JSON |

### Complete Error Handling Example

```swift
let result = await client.post("/users", body: newUser)

switch result {
case .success(let success):
    print("✅ Created user")
    print("Signature: \(success.requestSignature)")
case .failure(let failure):
    print("❌ Request failed with signature: \(failure.requestSignature)")
    
    switch failure.error {
    case .invalidURL:
        print("The URL was malformed")
    case .server(let code, let data):
        print("Server responded with status: \(code)")
        if let data = data {
            print(String(decoding: data, as: UTF8.self))
        }
    case .invalidResponse:
        print("No HTTPURLResponse received")
    case .transport(let err):
        print("Network error: \(err.localizedDescription)")
    case .encoding(let err):
        print("Encoding error: \(err.localizedDescription)")
    }
}
```

## <br><br> Testing with MockMercury

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
        
        await mock.setPostResult(
            .success(
                MercurySuccess(
                    data: Data(),
                    response: expectedResponse,
                    requestSignature: "test-signature"
                )
            )
        )
        
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

## <br><br> License

Mercury is available under the MIT License. See the [LICENSE](./LICENSE) file for more details.

---

By Josh Gallant, Made with ❤️ for the Swift community
