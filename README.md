<div align="center">

<h1>SwiftHTTPClient</h1>

[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20iPadOS%2016%2B%20%7C%20macOS%2013%2B%20%7C%20watchOS%209%2B%20%7C%20tvOS%2016%2B%20%7C%20visionOS%201%2B-blue.svg?style=flat)](#requirements)
<br>

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat)](https://swift.org)
[![SPM ready](https://img.shields.io/badge/SPM-ready-brightgreen.svg?style=flat-square)](https://swift.org/package-manager/)
[![Coverage](https://img.shields.io/badge/Coverage-98.3%25-brightgreen.svg?style=flat)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>

A modern and lightweight Swift HTTP client featuring Swift 6 actor isolation, async/await, cache support, and ergonomic request building.

## <br><br> Features
- Actor-isolated for safe concurrency (Swift 6 actors)
- Fully async/await API
- First-class request & response modeling
- Built-in cache support (URLCache)
- Customizable headers, session, and base URL
- Automatic URL normalization
- Simple, ergonomic API for all HTTP verbs
- Fully Tested

## <br><br> Installation

Add SwiftHTTPClient to your dependencies in Package.swift:

```Swift
.package(url: "https://github.com/joshgallantt/SwiftHTTPClient.git", from: "1.0.0")
```
Or via Xcode: File > Add Packages… and search for this repo URL.

## <br><br> Basic Usage

Import the package:

```Swift
import SwiftHTTPClient
```

Create an HTTP client instance:

```Swift
let client = HTTPClient(host: "https://api.example.com")
```

Perform a GET request:

```Swift
let result = await client.get("/users/42")
```

Handle the result:

```Swift
switch result {
case .success(let response):
    print(String(data: response.data, encoding: .utf8) ?? "")
    print("Status code:", response.response.statusCode)
case .failure(let error):
    print("Request failed:", error)
}
```

POST with an Encodable body:

```Swift
struct Item: Encodable {
    let name: String
}

let result = await client.post("/items", body: Item(name: "Swift"))
```

POST with Data Payload:

```Swift
let payload = "field1=value1&field2=value2".data(using: .utf8)!
let result = await client.post(
    "/submit",
    headers: ["Content-Type": "application/x-www-form-urlencoded"],
    data: payload
)
```

## <br><br> Cache Control

SwiftHTTPClient uses `URLCache` under the hood and supports **cache policy overrides** per request.

### Default Behavior

When initializing the `HTTPClient`, you can specify a default `URLRequest.CachePolicy`. This value applies to all requests **unless explicitly overridden**.

```swift
let client = HTTPClient(
    host: "https://api.example.com",
    defaultCachePolicy: .returnCacheDataElseLoad
)
```

### Per-Request Override

You can override the cache policy for **any** individual request:

```swift
let result = await client.get(
    "/weather/today",
    cachePolicy: .reloadIgnoringLocalCacheData
)
```

This allows for fine-grained control without affecting the global configuration.


## <br><br> Headers

Set commonHeaders when creating your client to send headers with every request.

Use the headers parameter to override or add headers for a single request. If a key appears in both, the per-request header wins.

```Swift
let client = HTTPClient(
    host: "https://api.example.com",
    commonHeaders: [
        "Content-Type": "application/json",
        "X-Client-Version": "1.0"
    ]
)

let result = await client.post(
    "/upload",
    headers: [
        "Content-Type": "image/png", // overrides common header
        "X-Request-ID": "abc-123"    // adds an extra header
    ],
    data: imageData
)
```

## <br><br> Query Parameters and URL Fragments

You can add query parameters and URL fragments to any request.

Use the queryItems parameter to pass query parameters as a `[String: String]` dictionary.

Use the fragment parameter to append a fragment to the URL.

```Swift
let result = await client.get(
    "/search",
    queryItems: [
        "q": "swift",
        "limit": "10"
    ],
    fragment: "section2"
)
```

This produces a request to:

```Swift
https://api.example.com/search?q=swift&limit=10#section2
```

## <br><br> Results: HTTPSuccess and HTTPFailure

All HTTPClient methods return a `Result<HTTPSuccess, HTTPFailure>`.

### <br> HTTPSuccess

Represents a successful HTTP response (2xx). Contains:

```Swift
struct HTTPSuccess: Sendable {
    let data: Data
    let response: HTTPURLResponse
}
```

- data — the response body as Data
- response — the HTTPURLResponse (status code, headers, etc)

### <br> HTTPFailure

Represents a failed request. Possible cases:
```Swift
enum HTTPFailure: Error, CustomStringConvertible, Sendable {
    case invalidURL
    case server(statusCode: Int, data: Data?)
    case invalidResponse
    case transport(Error)
    case encoding(Error)
}
```

- .invalidURL — The URL is invalid or could not be constructed.
- .server(statusCode:data:) — The server returned a non-2xx status code (with optional error body).
- .invalidResponse — Response was missing or malformed.
- .transport(Error) — A transport-layer error occurred (such as network down, timeout).
- .encoding(Error) — Failed to encode the request body.

All HTTPFailure values have a human-readable .description for easy logging.

#### <br> Example usage

```Swift
let result = await client.get("/resource")

switch result {
case .success(let output):
    print("Data: \(output.data)")
    print("Status code: \(output.response.statusCode)")
    
case .failure(let error):
    print("Request failed: \(error.description)")
}
```

Created by Josh Gallant. MIT License.
