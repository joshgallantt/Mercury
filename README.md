<div align="center">

<h1>SwiftHTTPClient</h1>

[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B%20%7C%20iPadOS%2015%2B%20%7C%20macOS%2012%2B%20%7C%20watchOS%208%2B-blue.svg?style=flat)](#requirements)
<br>

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat)](https://swift.org)
[![SPM ready](https://img.shields.io/badge/SPM-ready-brightgreen.svg?style=flat-square)](https://swift.org/package-manager/)
[![Coverage](https://img.shields.io/badge/Coverage-94%25-brightgreen.svg?style=flat)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>

A modern and lightweight Swift HTTP client featuring Swift 6 actor isolation, fully async/await, cache support, and ergonomic request building.


## <br> Features
- Actor-isolated for safe concurrency (Swift 6 actors)
- Fully async/await API
- First-class request & response modeling
- Built-in cache support (URLCache)
- Customizable headers, session, and base URL
- Automatic URL normalization
- Simple, ergonomic API for all HTTP verbs
- Fully Tested



## <br> Installation

Swift Package Manager:

Add the following to your Package.swift dependencies:

```Swift
.package(url: "https://github.com/joshgallantt/SwiftHTTPClient.git", from: "1.0.0")
```

Or via Xcode: File > Add Packages... and search for this repository URL.



## <br> Basic Usage

### Creating a Client

```Swift
import SwiftHTTPClient

let client = HTTPClient(host: "https://api.example.com")
```

### Performing Requests

#### GET:

```Swift
let result = await client.get("/users/42?expand=details")

switch result {
case .success(let response):
    print(String(data: response.data, encoding: .utf8) ?? "")
    print("Status code:", response.response.statusCode)
case .failure(let error):
    print("Request failed: \(error)")
}
```

#### POST:

You can POST using either any Swift type conforming to `Encodable` (preferred for JSON), or raw `Data` if you have a custom payload.

**Using an Encodable type (preferred for JSON APIs):**

```swift
struct Item: Encodable {
    let name: String
}

let result = await client.post("/items", body: Item(name: "Swift"))

switch result {
case .success(let response):
    print(String(data: response.data, encoding: .utf8) ?? "")
    print("Status code:", response.response.statusCode)
case .failure(let error):
    print("Request failed: \(error)")
}
```

**Using raw Data (for custom or non-JSON payloads):**

```swift
let postData = try JSONEncoder().encode(["name": "Swift"])

let result = await client.post("/items", data: postData)

switch result {
case .success(let response):
    print(String(data: response.data, encoding: .utf8) ?? "")
    print("Status code:", response.response.statusCode)
case .failure(let error):
    print("Request failed: \(error)")
}
```

> **Tip:**
> For most JSON APIs, use the `body:` parameter with your `Encodable` Swift structs or dictionaries.
> Use the `data:` parameter for sending pre-encoded or binary payloads.

All verbs (GET, POST, PUT, PATCH, DELETE) are supported with identical ergonomics.

### Query Parameters and Fragments

```Swift
let result = await client.get("/things", queryItems: ["page": "1", "q": "foo"], fragment: "details")
```

### Headers

```Swift
let result = await client.get("/me", headers: ["Authorization": "Bearer TOKEN"])
```


## <br> Advanced Usage

### Custom URLSession

You can inject your own URLSession (or any HTTPSession) for testing or custom configuration:

```Swift
let customSession = URLSession(configuration: .ephemeral)
let client = HTTPClient(host: "api.example.com", session: customSession)
```

### Controlling Cache

Each request can specify a cache policy:

```Swift
let result = await client.get("/cache", cachePolicy: .reloadIgnoringLocalCacheData)
```

### Customizing Default Headers

Default common headers are pre-applied, but you can override them if you want the client to always use certain ones.

```Swift
let client = HTTPClient(host: "api.example.com", commonHeaders: [
    "Accept": "application/json",
    "Authorization": "Bearer ..."
])
```



## <br> Testing

This package includes comprehensive tests for URL normalization, error handling, and all HTTP methods (see HTTPClientTests.swift).


## <br> License

MIT. See LICENSE for details.



## <br> Credits

Created by Josh Gallant.
