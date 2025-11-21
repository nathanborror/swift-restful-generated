# Restful

An API agnostic, lightweight Swift library for making RESTful HTTP requests with a simple, intuitive interface.

## Features

- ✅ Simple and intuitive API
- ✅ Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
- ✅ Async/await support
- ✅ Automatic JSON serialization/deserialization using `JSONValue`
- ✅ Type-safe JSON handling with the JSONSchema library
- ✅ Key-path traversal for easy nested value access
- ✅ Custom headers support
- ✅ Comprehensive error handling
- ✅ Custom URLSession configuration
- ✅ Strongly typed errors

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-restful-generated", from: "1.0.0")
]
```

Or add it through Xcode:
1. File > Add Package Dependencies
2. Enter the package repository URL
3. Select the version you want to use

## Quick Start

```swift
import Restful

let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/users",
    method: "GET"
)

print(response)
```

## Usage Examples

### Basic GET Request

```swift
import Restful

let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/users/1",
    method: "GET"
)

// Traditional access
if let name = response["name"]?.stringValue {
    print("User name: \(name)")
}

// Or using key-path for nested values
if let email = response[keyPath: "profile.email"]?.stringValue {
    print("Email: \(email)")
}
```

### POST Request with Body
</text>

<old_text line=88>
print(response["data"])
```

### PUT Request to Update Resource

```swift
let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/users",
    method: "POST",
    body: [
        "name": "John Doe",
        "email": "john@example.com",
        "age": 30
    ]
)

print("Created user:", response)
```

### Request with Authentication Headers

```swift
let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/protected",
    method: "GET",
    headers: [
        "Authorization": "Bearer YOUR_API_TOKEN",
        "Accept": "application/json"
    ]
)
```

### OpenAI API Example

```swift
import Restful

let session = RestfulSession()

let response = try await session.request(
    url: "https://api.openai.com/v1/chat/completions",
    method: "POST",
    body: [
        "model": "gpt-4o-mini",
        "messages": JSONValue.array([
            JSONValue.object(["role": "user", "content": "Hello, World!"])
        ])
    ],
    headers: [
        "Authorization": "Bearer API_TOKEN",
        "Content-Type": "application/json"
    ]
)

// Access nested response data using key-path traversal
if let content = response[keyPath: "choices.0.message.content"]?.stringValue {
    print("Assistant: \(content)")
}

if let model = response[keyPath: "model"]?.stringValue {
    print("Model: \(model)")
}
```

### PUT Request to Update Resource

```swift
let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/users/123",
    method: "PUT",
    body: [
        "name": "Jane Doe",
        "email": "jane@example.com"
    ],
    headers: [
        "Authorization": "Bearer YOUR_TOKEN"
    ]
)
```

### DELETE Request

```swift
let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/users/123",
    method: "DELETE",
    headers: [
        "Authorization": "Bearer YOUR_TOKEN"
    ]
)
```

## Error Handling

The library provides comprehensive error handling through the `RestfulError` enum:

```swift
do {
    let response = try await session.request(
        url: "https://api.example.com/data",
        method: "GET"
    )
    // Process successful response
    print("Success:", response)
    
} catch RestfulError.invalidURL(let url) {
    print("Invalid URL: \(url)")
    
} catch RestfulError.httpError(let statusCode, let data) {
    print("HTTP error \(statusCode)")
    if let errorMessage = String(data: data, encoding: .utf8) {
        print("Server message: \(errorMessage)")
    }
    
} catch RestfulError.invalidResponseFormat {
    print("Response is not valid JSON object")
    
} catch RestfulError.decodingError(let error) {
    print("Failed to decode response: \(error)")
    
} catch RestfulError.invalidBody(let error) {
    print("Invalid request body: \(error)")
    
} catch RestfulError.invalidResponse {
    print("Invalid HTTP response")
    
} catch {
    print("Unexpected error: \(error)")
}
```

### Error Types

- `invalidURL(String)` - The provided URL string is invalid
- `invalidBody(Error)` - The request body cannot be serialized to JSON
- `invalidResponse` - The response is not a valid HTTP response
- `invalidResponseFormat` - The response is not a valid JSON object (e.g., array instead of object)
- `httpError(statusCode: Int, data: Data)` - The server returned an error status code (not 2xx)
- `decodingError(Error)` - Failed to decode the response JSON

## Advanced Usage

### Custom URLSession Configuration

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60

let urlSession = URLSession(configuration: config)
let session = RestfulSession(urlSession: urlSession)

let response = try await session.request(
    url: "https://api.example.com/data",
    method: "GET"
)
```

### Complex Nested JSON Body

```swift
let response = try await session.request(
    url: "https://api.example.com/orders",
    method: "POST",
    body: [
        "customer": JSONValue.object([
            "name": "John Doe",
            "email": "john@example.com",
        ]),
        "items": JSONValue.array([
            JSONValue.object(["product": "Widget", "quantity": 2]),
            JSONValue.object(["product": "Gadget", "quantity": 1]),
        ]),
        "total": 99.99,
        "currency": "USD"
    ],
    headers: [
        "Authorization": "Bearer YOUR_TOKEN"
    ]
)
```

### Multiple Sequential Requests

```swift
let session = RestfulSession()

// First request
let user = try await session.request(
    url: "https://api.example.com/users/1",
    method: "GET"
)

// Second request using data from first
if let userId = user["id"]?.intValue {
    let posts = try await session.request(
        url: "https://api.example.com/users/\(userId)/posts",
        method: "GET"
    )
    print("User posts:", posts)
}
```

## Working with JSONValue

This library uses the `JSONValue` type from the [JSONSchema](https://github.com/mattt/JSONSchema) library to represent JSON data. This provides type-safe handling of JSON values.

### Creating JSON Values

`JSONValue` conforms to literal protocols, so you can use Swift literals directly:

```swift
let body: [String: JSONValue] = [
    "name": "John Doe",        // String literal
    "age": 30,                  // Integer literal
    "active": true,             // Boolean literal
    "score": 98.5              // Double literal
]
```

For nested structures, use explicit constructors:

```swift
let body: [String: JSONValue] = [
    "user": JSONValue.object([
        "name": "John Doe",
        "email": "john@example.com"
    ]),
    "tags": JSONValue.array(["swift", "api", "rest"])
]
```

### Accessing JSON Values

Use the type-specific properties to extract values:

```swift
let response = try await session.request(url: "...", method: "GET")

// Access string values
if let name = response["name"]?.stringValue {
    print("Name: \(name)")
}

// Access integer values
if let age = response["age"]?.intValue {
    print("Age: \(age)")
}

// Access boolean values
if let active = response["active"]?.boolValue {
    print("Active: \(active)")
}

// Access double values
if let score = response["score"]?.doubleValue {
    print("Score: \(score)")
}

// Access arrays
if let items = response["items"]?.arrayValue {
    print("Found \(items.count) items")
}

// Access nested objects
if let user = response["user"]?.objectValue {
    print("User name: \(user["name"]?.stringValue ?? "Unknown")")
}
```

### Key-Path Traversal

For easier access to nested values, use key-path notation with dot separators and numeric array indices:

```swift
let response = try await session.request(url: "...", method: "GET")

// Simple nested object access
if let name = response[keyPath: "user.name"]?.stringValue {
    print("Name: \(name)")
}

// Deep nesting
if let summary = response[keyPath: "output.reasoning.summary"]?.stringValue {
    print("Summary: \(summary)")
}

// Array access with numeric indices
if let firstItem = response[keyPath: "items.0"]?.stringValue {
    print("First item: \(firstItem)")
}

// Mixed nesting with objects and arrays
if let title = response[keyPath: "data.results.0.title"]?.stringValue {
    print("First result title: \(title)")
}

// Complex nested structures
if let theme = response[keyPath: "user.profile.settings.theme"]?.stringValue {
    print("Theme: \(theme)")
}
```

This is much simpler than chaining optional access:

```swift
// Without key-path (verbose)
if let user = response["user"]?.objectValue,
   let profile = user["profile"]?.objectValue,
   let settings = profile["settings"]?.objectValue,
   let theme = settings["theme"]?.stringValue {
    print("Theme: \(theme)")
}

// With key-path (concise)
if let theme = response[keyPath: "user.profile.settings.theme"]?.stringValue {
    print("Theme: \(theme)")
}
```

## API Reference

### RestfulSession

The main class for making HTTP requests.

#### Initializer

```swift
init(urlSession: URLSession = .shared)
```

Creates a new `RestfulSession` with an optional custom `URLSession`.

#### Methods

```swift
func request(
    url: String,
    method: String,
    body: [String: JSONValue]? = nil,
    headers: [String: String]? = nil
) async throws -> [String: JSONValue]
```

Makes an HTTP request and returns the JSON response as a dictionary.

**Parameters:**
- `url`: The URL string for the request
- `method`: The HTTP method (GET, POST, PUT, DELETE, PATCH, etc.)
- `body`: Optional request body as a dictionary (will be serialized to JSON)
- `headers`: Optional HTTP headers as a dictionary

**Returns:** The response as a dictionary `[String: JSONValue]`

**Throws:** `RestfulError` if the request fails

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available under the MIT license.
