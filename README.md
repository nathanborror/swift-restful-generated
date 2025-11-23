# Restful

An API agnostic, lightweight Swift library for making RESTful HTTP requests with a simple, intuitive interface.

## Features

- ✅ Simple and intuitive API
- ✅ Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
- ✅ Async/await support
- ✅ Server-sent events (SSE) streaming support
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

## Examples

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

```swift
let session = RestfulSession()

let response = try await session.request(
    url: "https://api.example.com/users",
    method: "POST",
    body: [
        "name": "John Doe",
        "email": "john@example.com",
        "age": 30
    ],
    headers: [
        "Authorization": "Bearer YOUR_API_TOKEN",
        "Accept": "application/json"
    ]
)

print("Created user:", response)
```

### OpenAI API Example

```swift
import Restful

let session = RestfulSession()

let response = try await session.request(
    url: "https://api.openai.com/v1/responses",
    method: "POST",
    body: [
        "model": "gpt-4o-mini",
        "input": "hello"
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

### Streaming with Server-Sent Events (SSE)

Server-sent events allow you to receive real-time updates from the server as they happen. This is perfect for streaming APIs like chat completions.

```swift
let session = RestfulSession()

let stream = session.stream(
    url: "https://api.openai.com/v1/responses",
    method: "POST",
    body: [
        "model": "gpt-4",
        "input": "tell me a story",
        "stream": true
    ],
    headers: [
        "Authorization": "Bearer YOUR_API_KEY",
        "Content-Type": "application/json"
    ]
)

for try await event in stream {
    // Each event contains the streamed data
    print("Received:", event.data)
    
    // Events can have optional metadata
    if let eventType = event.event {
        print("Event type:", eventType)
    }
    
    if let eventId = event.id {
        print("Event ID:", eventId)
    }
}
```

### Custom Event Types

SSE supports custom event types. You can filter or handle events differently based on their type:

```swift
let stream = session.stream(
    url: "https://api.example.com/notifications",
    method: "GET",
    headers: ["Authorization": "Bearer TOKEN"]
)

for try await event in stream {
    switch event.event {
    case "message":
        print("Message:", event.data)
    case "alert":
        print("Alert:", event.data)
    case "update":
        print("Update:", event.data)
    default:
        print("Unknown event:", event.data)
    }
}
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
    
} catch let RestfulError.httpError(statusCode, data) {
    print("HTTP error \(statusCode)")
    if let errorMessage = String(data: data, encoding: .utf8) {
        print("Server message: \(errorMessage)")
    }
    
} catch let RestfulError.httpErrorJSON(statusCode, errorData) {
    print("HTTP error \(statusCode)")
    if let message = errorData["message"]?.stringValue {
        print("Error message: \(message)")
    }
    if let code = errorData["error.code"]?.stringValue {
        print("Error code: \(code)")
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
- `httpError(statusCode: Int, data: Data)` - The server returned an error status code (not 2xx) with non-JSON data
- `httpErrorJSON(statusCode: Int, data: [String: JSONValue])` - The server returned an error status code (not 2xx) with JSON data
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
        "customer": .object([
            "name": "John Doe",
            "email": "john@example.com",
        ]),
        "items": .array([
            .object(["product": "Widget", "quantity": 2]),
            .object(["product": "Gadget", "quantity": 1]),
        ]),
        "total": 99.99,
        "currency": "USD"
    ],
    headers: [
        "Authorization": "Bearer YOUR_TOKEN"
    ]
)
```

## Working with JSONValue

This library uses the `JSONValue` type from the [JSONSchema](https://github.com/mattt/JSONSchema) library to represent JSON data. This provides type-safe handling of JSON values.

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
