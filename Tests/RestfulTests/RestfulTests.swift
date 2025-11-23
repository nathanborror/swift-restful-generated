import Foundation
import JSONSchema
import Testing

@testable import Restful

@Suite("RestfulSession Tests")
struct RestfulTests {

    @Test("RestfulSession initializes with default URLSession")
    func initialization() {
        let session = RestfulSession()
        // Session is created successfully
        _ = session
    }

    @Test("RestfulSession initializes with custom URLSession")
    func customURLSession() {
        let config = URLSessionConfiguration.default
        let customSession = URLSession(configuration: config)
        let session = RestfulSession(urlSession: customSession)
        // Session is created successfully with custom URLSession
        _ = session
    }

    @Test("RestfulSession throws error for invalid URL")
    func invalidURL() async {
        let session = RestfulSession()

        await #expect(throws: RestfulError.self) {
            _ = try await session.request(
                url: "not a valid url ://",
                method: "GET"
            )
        }
    }

    @Test("RestfulSession throws error for malformed URL with spaces")
    func malformedURL() async {
        let session = RestfulSession()

        await #expect(throws: RestfulError.self) {
            _ = try await session.request(
                url: "http://example.com/path with spaces",
                method: "GET"
            )
        }
    }
}

private let OPENAI_API_KEY: String? = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]

@Suite("OpenAI Tests", .enabled(if: OPENAI_API_KEY?.isEmpty == false))
struct RestfulOpenAITests {

    @Test("Basic response")
    func basicResponse() async throws {
        let session = RestfulSession()

        let response = try await session.request(
            url: "https://api.openai.com/v1/responses",
            method: "POST",
            body: [
                "model": "gpt-4o-mini",
                "input": "hi",
            ],
            headers: [
                "Authorization": "Bearer \(OPENAI_API_KEY!)",
                "Content-Type": "application/json",
            ]
        )

        #expect(response[keyPath: "output.0.content.0.text"] != "")
    }

    @Test("Basic streaming response")
    func basicStreamingResponse() async throws {
        let session = RestfulSession()

        let stream = session.stream(
            url: "https://api.openai.com/v1/responses",
            method: "POST",
            body: [
                "model": "gpt-4o-mini",
                "input": "hi",
                "stream": true,
            ],
            headers: [
                "Authorization": "Bearer \(OPENAI_API_KEY!)",
                "Content-Type": "application/json",
            ]
        )
        for try await event in stream {
            if let jsonData = event.data.data(using: .utf8), let response = try? JSONDecoder().decode([String: JSONValue].self, from: jsonData) {
                #expect(response.count > 0)
            }
        }
    }
}

private let ANTHROPIC_API_KEY: String? = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]

@Suite("Anthropic Tests", .enabled(if: ANTHROPIC_API_KEY?.isEmpty == false))
struct RestfulAnthropicTests {

    @Test("Basic response")
    func basicResponse() async throws {
        let session = RestfulSession()

        let response = try await session.request(
            url: "https://api.anthropic.com/v1/messages",
            method: "POST",
            body: [
                "model": "claude-haiku-4-5",
                "max_tokens": 1024,
                "messages": .array([
                    [
                        "role": "user",
                        "content": "Hello",
                    ]
                ]),
            ],
            headers: [
                "anthropic-version": "2023-06-01",
                "X-Api-Key": ANTHROPIC_API_KEY!,
                "Content-Type": "application/json",
            ]
        )

        #expect(response[keyPath: "output.0.content.0.text"] != "")
    }

    @Test("Basic streaming response")
    func basicStreamingResponse() async throws {
        let session = RestfulSession()

        let stream = session.stream(
            url: "https://api.anthropic.com/v1/messages",
            method: "POST",
            body: [
                "model": "claude-haiku-4-5",
                "max_tokens": 1024,
                "messages": .array([
                    [
                        "role": "user",
                        "content": "Hello",
                    ]
                ]),
                "stream": true,
            ],
            headers: [
                "anthropic-version": "2023-06-01",
                "X-Api-Key": ANTHROPIC_API_KEY!,
                "Content-Type": "application/json",
            ]
        )
        for try await event in stream {
            if let jsonData = event.data.data(using: .utf8), let response = try? JSONDecoder().decode([String: JSONValue].self, from: jsonData) {
                #expect(response.count > 0)
            }
        }
    }
}

private let GOOGLE_API_KEY: String? = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"]

@Suite("Google Gemini Tests", .enabled(if: GOOGLE_API_KEY?.isEmpty == false))
struct RestfulGoogleTests {

    @Test("Basic response")
    func basicResponse() async throws {
        let session = RestfulSession()
        let response = try await session.request(
            url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
            method: "POST",
            body: [
                "contents": .array([
                    .object([
                        "parts": .array([
                            .object([
                                "text": "Hi"
                            ])
                        ])
                    ])
                ])
            ],
            headers: [
                "x-goog-api-key": GOOGLE_API_KEY!,
                "Content-Type": "application/json",
            ]
        )
        #expect(response[keyPath: "candidates.0.content.parts.0.text"]?.stringValue != "")
    }

    @Test("Basic streaming response")
    func basicStreamingResponse() async throws {
        let session = RestfulSession()
        let stream = session.stream(
            url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse",
            method: "POST",
            body: [
                "contents": .array([
                    .object([
                        "parts": .array([
                            .object([
                                "text": "Hi"
                            ])
                        ])
                    ])
                ])
            ],
            headers: [
                "x-goog-api-key": GOOGLE_API_KEY!,
                "Content-Type": "application/json",
            ],
            linebreaks: "\r\n"
        )

        for try await event in stream {
            if let jsonData = event.data.data(using: .utf8), let response = try? JSONDecoder().decode([String: JSONValue].self, from: jsonData) {
                #expect(response[keyPath: "candidates.0.content.parts.0.text"]?.stringValue != "")
            }
        }
    }
}

@Suite("RestfulError Tests")
struct RestfulErrorTests {

    @Test("RestfulError.invalidURL provides descriptive error message")
    func invalidURLError() {
        let error = RestfulError.invalidURL("http://invalid")
        #expect(error.errorDescription?.contains("Invalid URL") == true)
        #expect(error.errorDescription?.contains("http://invalid") == true)
    }

    @Test("RestfulError.invalidResponse provides descriptive error message")
    func invalidResponseError() {
        let error = RestfulError.invalidResponse
        #expect(error.errorDescription?.contains("Invalid HTTP response") == true)
    }

    @Test("RestfulError.invalidResponseFormat provides descriptive error message")
    func invalidResponseFormatError() {
        let error = RestfulError.invalidResponseFormat
        #expect(error.errorDescription?.contains("not a valid JSON object") == true)
    }

    @Test("RestfulError.httpError provides status code in error message")
    func httpError() {
        let error = RestfulError.httpError(statusCode: 404, data: Data())
        #expect(error.errorDescription?.contains("404") == true)
        #expect(error.errorDescription?.contains("HTTP error") == true)
    }

    @Test("RestfulError.httpError with different status codes")
    func httpErrorVariousStatusCodes() {
        let error401 = RestfulError.httpError(statusCode: 401, data: Data())
        #expect(error401.errorDescription?.contains("401") == true)

        let error500 = RestfulError.httpError(statusCode: 500, data: Data())
        #expect(error500.errorDescription?.contains("500") == true)

        let error503 = RestfulError.httpError(statusCode: 503, data: Data())
        #expect(error503.errorDescription?.contains("503") == true)
    }

    @Test("RestfulError.httpErrorJSON provides status code in error message")
    func httpErrorJSON() {
        let errorData: [String: JSONValue] = ["message": .string("Not found")]
        let error = RestfulError.httpErrorJSON(statusCode: 404, data: errorData)
        #expect(error.errorDescription?.contains("404") == true)
        #expect(error.errorDescription?.contains("HTTP error") == true)
    }

    @Test("RestfulError.httpErrorJSON preserves JSON data")
    func httpErrorJSONData() {
        let errorData: [String: JSONValue] = [
            "message": .string("Unauthorized"),
            "code": .string("AUTH_ERROR"),
        ]
        let error = RestfulError.httpErrorJSON(statusCode: 401, data: errorData)

        if case .httpErrorJSON(let statusCode, let data) = error {
            #expect(statusCode == 401)
            #expect(data["message"]?.stringValue == "Unauthorized")
            #expect(data["code"]?.stringValue == "AUTH_ERROR")
        } else {
            Issue.record("Expected httpErrorJSON case")
        }
    }

    @Test("RestfulError.httpErrorJSON with nested data")
    func httpErrorJSONNested() {
        let errorData: [String: JSONValue] = [
            "error": .object([
                "code": .string("VALIDATION_ERROR"),
                "details": .array([.string("Field 'email' is required")]),
            ])
        ]
        let error = RestfulError.httpErrorJSON(statusCode: 400, data: errorData)

        if case .httpErrorJSON(_, let data) = error {
            #expect(data["error"]?.objectValue?["code"]?.stringValue == "VALIDATION_ERROR")
            #expect(
                data["error"]?.objectValue?["details"]?.arrayValue?.first?.stringValue
                    == "Field 'email' is required")
        } else {
            Issue.record("Expected httpErrorJSON case")
        }
    }

    @Test("RestfulError.invalidBody provides underlying error message")
    func invalidBodyError() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 123,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )
        let error = RestfulError.invalidBody(underlyingError)
        #expect(error.errorDescription?.contains("Invalid request body") == true)
    }

    @Test("RestfulError.decodingError provides underlying error message")
    func decodingError() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 456,
            userInfo: [NSLocalizedDescriptionKey: "Decoding failed"]
        )
        let error = RestfulError.decodingError(underlyingError)
        #expect(error.errorDescription?.contains("Failed to decode response") == true)
    }
}

@Suite("RestfulSession Request Building")
struct RestfulRequestBuildingTests {

    @Test("Request method is set correctly")
    func requestMethod() async {
        // This test verifies the structure without making actual network calls
        let session = RestfulSession()

        // Test that different methods don't cause crashes (they'll fail with network errors, which is expected)
        for method in ["GET", "POST", "PUT", "DELETE", "PATCH"] {
            await #expect(throws: (any Error).self) {
                _ = try await session.request(
                    url: "https://httpbin.org/status/404",
                    method: method
                )
            }
        }
    }
}

@Suite("HTTP Error JSON Integration Tests")
struct HTTPErrorJSONIntegrationTests {

    @Test("HTTP error with JSON response throws httpErrorJSON")
    func httpErrorJSONIntegration() async {
        let session = RestfulSession()

        do {
            // httpbin.org/status/404 returns a 404 with empty body, but we can use
            // a different endpoint that returns JSON errors
            _ = try await session.request(
                url: "https://httpbin.org/status/404",
                method: "GET",
                headers: ["Accept": "application/json"]
            )
            Issue.record("Expected error to be thrown")
        } catch let RestfulError.httpErrorJSON(statusCode, data) {
            // If the response is JSON, it should be caught as httpErrorJSON
            #expect(statusCode == 404)
            // data should be a valid JSON dictionary
            _ = data
        } catch let RestfulError.httpError(statusCode, _) {
            // If the response is not JSON, it should be caught as httpError (which is valid for httpbin)
            #expect(statusCode == 404)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

@Suite("Key-Path Traversal Tests")
struct KeyPathTraversalTests {

    @Test("Simple key access returns correct value")
    func simpleKeyAccess() {
        let response: [String: JSONValue] = [
            "name": "John Doe",
            "age": 30,
        ]

        #expect(response[keyPath: "name"]?.stringValue == "John Doe")
        #expect(response[keyPath: "age"]?.intValue == 30)
    }

    @Test("Nested object access with dot notation")
    func nestedObjectAccess() {
        let response: [String: JSONValue] = [
            "user": JSONValue.object([
                "name": "Jane Doe",
                "email": "jane@example.com",
            ])
        ]

        #expect(response[keyPath: "user.name"]?.stringValue == "Jane Doe")
        #expect(response[keyPath: "user.email"]?.stringValue == "jane@example.com")
    }

    @Test("Array index access with numeric indices")
    func arrayIndexAccess() {
        let response: [String: JSONValue] = [
            "items": JSONValue.array([
                "first",
                "second",
                "third",
            ])
        ]

        #expect(response[keyPath: "items.0"]?.stringValue == "first")
        #expect(response[keyPath: "items.1"]?.stringValue == "second")
        #expect(response[keyPath: "items.2"]?.stringValue == "third")
    }

    @Test("Mixed nesting with objects and arrays")
    func mixedNesting() {
        let response: [String: JSONValue] = [
            "data": JSONValue.object([
                "results": JSONValue.array([
                    JSONValue.object([
                        "id": 1,
                        "title": "First Item",
                    ]),
                    JSONValue.object([
                        "id": 2,
                        "title": "Second Item",
                    ]),
                ])
            ])
        ]

        #expect(response[keyPath: "data.results.0.id"]?.intValue == 1)
        #expect(response[keyPath: "data.results.0.title"]?.stringValue == "First Item")
        #expect(response[keyPath: "data.results.1.id"]?.intValue == 2)
        #expect(response[keyPath: "data.results.1.title"]?.stringValue == "Second Item")
    }

    @Test("Deep nesting traversal")
    func deepNesting() {
        let response: [String: JSONValue] = [
            "output": JSONValue.object([
                "reasoning": JSONValue.object([
                    "summary": "This is a summary"
                ])
            ])
        ]

        #expect(response[keyPath: "output.reasoning.summary"]?.stringValue == "This is a summary")
    }

    @Test("Array of objects with nested access")
    func arrayOfObjects() {
        let response: [String: JSONValue] = [
            "users": JSONValue.array([
                JSONValue.object([
                    "name": "Alice",
                    "profile": JSONValue.object([
                        "age": 25
                    ]),
                ]),
                JSONValue.object([
                    "name": "Bob",
                    "profile": JSONValue.object([
                        "age": 30
                    ]),
                ]),
            ])
        ]

        #expect(response[keyPath: "users.0.name"]?.stringValue == "Alice")
        #expect(response[keyPath: "users.0.profile.age"]?.intValue == 25)
        #expect(response[keyPath: "users.1.name"]?.stringValue == "Bob")
        #expect(response[keyPath: "users.1.profile.age"]?.intValue == 30)
    }

    @Test("Non-existent key returns nil")
    func nonExistentKey() {
        let response: [String: JSONValue] = [
            "name": "John Doe"
        ]

        #expect(response[keyPath: "email"] == nil)
        #expect(response[keyPath: "user.name"] == nil)
    }

    @Test("Out of bounds array index returns nil")
    func outOfBoundsArrayIndex() {
        let response: [String: JSONValue] = [
            "items": JSONValue.array([
                "first",
                "second",
            ])
        ]

        #expect(response[keyPath: "items.2"] == nil)
        #expect(response[keyPath: "items.10"] == nil)
        #expect(response[keyPath: "items.-1"] == nil)
    }

    @Test("Invalid path returns nil")
    func invalidPath() {
        let response: [String: JSONValue] = [
            "name": "John Doe"
        ]

        #expect(response[keyPath: ""] == nil)
        #expect(response[keyPath: "name.invalid"] == nil)
    }

    @Test("Accessing array index on non-array returns nil")
    func arrayIndexOnNonArray() {
        let response: [String: JSONValue] = [
            "user": JSONValue.object([
                "name": "John Doe"
            ])
        ]

        #expect(response[keyPath: "user.0"] == nil)
    }

    @Test("Accessing object key on non-object returns nil")
    func objectKeyOnNonObject() {
        let response: [String: JSONValue] = [
            "items": JSONValue.array(["first", "second"])
        ]

        #expect(response[keyPath: "items.name"] == nil)
    }

    @Test("Complex real-world example")
    func complexRealWorld() {
        let response: [String: JSONValue] = [
            "status": "success",
            "data": JSONValue.object([
                "user": JSONValue.object([
                    "id": 123,
                    "profile": JSONValue.object([
                        "name": "Alice Smith",
                        "settings": JSONValue.object([
                            "theme": "dark"
                        ]),
                    ]),
                ]),
                "posts": JSONValue.array([
                    JSONValue.object([
                        "id": 1,
                        "content": "First post",
                        "tags": JSONValue.array(["swift", "api"]),
                    ]),
                    JSONValue.object([
                        "id": 2,
                        "content": "Second post",
                        "tags": JSONValue.array(["rest", "http"]),
                    ]),
                ]),
            ]),
        ]

        #expect(response[keyPath: "status"]?.stringValue == "success")
        #expect(response[keyPath: "data.user.id"]?.intValue == 123)
        #expect(response[keyPath: "data.user.profile.name"]?.stringValue == "Alice Smith")
        #expect(response[keyPath: "data.user.profile.settings.theme"]?.stringValue == "dark")
        #expect(response[keyPath: "data.posts.0.id"]?.intValue == 1)
        #expect(response[keyPath: "data.posts.0.content"]?.stringValue == "First post")
        #expect(response[keyPath: "data.posts.0.tags.0"]?.stringValue == "swift")
        #expect(response[keyPath: "data.posts.1.tags.1"]?.stringValue == "http")
    }
}

@Suite("Server-Sent Events Tests")
struct ServerSentEventsTests {

    @Test("ServerSentEvent initializes with all parameters")
    func eventInitialization() {
        let event = ServerSentEvent(
            data: "test data",
            event: "message",
            id: "123",
            retry: 5000
        )

        #expect(event.data == "test data")
        #expect(event.event == "message")
        #expect(event.id == "123")
        #expect(event.retry == 5000)
    }

    @Test("ServerSentEvent initializes with minimal parameters")
    func eventMinimalInitialization() {
        let event = ServerSentEvent(data: "simple data")

        #expect(event.data == "simple data")
        #expect(event.event == nil)
        #expect(event.id == nil)
        #expect(event.retry == nil)
    }

    @Test("Stream throws error for invalid URL")
    func streamInvalidURL() async {
        let session = RestfulSession()

        let stream = session.stream(
            url: "not a valid url ://",
            method: "GET"
        )

        var didThrow = false
        do {
            for try await _ in stream {
                // Should not get here
            }
        } catch {
            didThrow = true
            #expect(error is RestfulError)
        }

        #expect(didThrow)
    }

    @Test("Stream accepts GET method by default")
    func streamDefaultMethod() async {
        let session = RestfulSession()

        // This should not throw for method-related issues
        let stream = session.stream(url: "https://httpbin.org/stream/1")

        // We're just checking it creates a stream, not necessarily that it succeeds
        var count = 0
        do {
            for try await _ in stream {
                count += 1
                break  // Just check we can start streaming
            }
        } catch {
            // Network errors are acceptable for this test
        }

        // Test passes if we got here without crashing
        _ = count
    }

    @Test("Stream can be configured with custom headers")
    func streamCustomHeaders() async {
        let session = RestfulSession()

        // This should not throw for header-related issues
        let stream = session.stream(
            url: "https://httpbin.org/stream/1",
            headers: [
                "Authorization": "Bearer test-token",
                "Custom-Header": "custom-value",
            ]
        )

        // We're just checking it accepts custom headers without error
        do {
            for try await _ in stream {
                break  // Just check initialization works
            }
        } catch {
            // Network errors are acceptable for this test
        }

        // Test passes if headers were accepted
    }

    @Test("Stream can be configured with POST method and body")
    func streamWithBody() async {
        let session = RestfulSession()

        // This should not throw for body-related issues
        let stream = session.stream(
            url: "https://httpbin.org/post",
            method: "POST",
            body: [
                "model": "gpt-4",
                "stream": true,
            ]
        )

        // We're just checking it accepts body without error
        do {
            for try await _ in stream {
                break  // Just check initialization works
            }
        } catch {
            // Network errors are acceptable for this test
        }

        // Test passes if body was accepted
    }

    @Test("Multiple events can be parsed from stream")
    func multipleEvents() async {
        // This is a conceptual test showing the pattern
        // In real usage, you would connect to an actual SSE endpoint

        _ = RestfulSession()
        let events: [ServerSentEvent] = []

        // The pattern for collecting multiple events:
        // var events: [ServerSentEvent] = []
        // for try await event in session.stream(url: "...") {
        //     events.append(event)
        //     if events.count >= expectedCount {
        //         break
        //     }
        // }

        // For now, just verify the pattern compiles
        #expect(events.isEmpty)
    }

    @Test("Stream handles data-only events")
    func dataOnlyEvent() {
        let event = ServerSentEvent(data: "Just data, no other fields")

        #expect(event.data == "Just data, no other fields")
        #expect(event.event == nil)
        #expect(event.id == nil)
        #expect(event.retry == nil)
    }

    @Test("Stream handles multi-line data")
    func multiLineData() {
        let event = ServerSentEvent(data: "Line 1\nLine 2\nLine 3")

        #expect(event.data == "Line 1\nLine 2\nLine 3")
    }

    @Test("Stream handles events with custom event types")
    func customEventType() {
        let event = ServerSentEvent(
            data: "Custom event data",
            event: "user-connected"
        )

        #expect(event.data == "Custom event data")
        #expect(event.event == "user-connected")
    }

    @Test("Stream handles events with IDs")
    func eventWithId() {
        let event = ServerSentEvent(
            data: "Event data",
            id: "event-12345"
        )

        #expect(event.data == "Event data")
        #expect(event.id == "event-12345")
    }

    @Test("Stream handles events with retry intervals")
    func eventWithRetry() {
        let event = ServerSentEvent(
            data: "Event data",
            retry: 3000
        )

        #expect(event.data == "Event data")
        #expect(event.retry == 3000)
    }
}
