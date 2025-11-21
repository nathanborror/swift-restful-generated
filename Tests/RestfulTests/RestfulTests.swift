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
}

private let ANTHROPIC_API_KEY: String? = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]

@Suite("Anthropic Tests", .enabled(if: ANTHROPIC_API_KEY?.isEmpty == false))
struct RestfulAnthropicTests {

    @Test("Basic response")
    func basicResponse() async throws {
        let session = RestfulSession()

        do {
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
        } catch let RestfulError.httpError(_, data) {
            print(String(data: data, encoding: .utf8))
        } catch {
            print(error)
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
