import Foundation
import JSONSchema

// MARK: - Basic Usage Examples

/// Example 1: Simple GET Request
func simpleGETRequest() async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.example.com/users",
        method: "GET"
    )

    print("Response:", response)
}

/// Example 2: POST Request with Body
func postRequestWithBody() async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.example.com/users",
        method: "POST",
        body: [
            "name": "John Doe",
            "email": "john@example.com",
            "age": 30,
        ]
    )

    print("Created user:", response)
}

/// Example 3: Request with Authentication Headers
func authenticatedRequest() async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.example.com/protected",
        method: "GET",
        headers: [
            "Authorization": "Bearer YOUR_API_TOKEN",
            "Accept": "application/json",
        ]
    )

    print("Protected data:", response)
}

/// Example 4: OpenAI API Request (from README)
func openAIRequest() async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.openai.com/v1/responses",
        method: "POST",
        body: [
            "model": "gpt-4o-mini",
            "input": "Hello, World!",
        ],
        headers: [
            "Authorization": "Bearer API_TOKEN",
            "Content-Type": "application/json",
        ]
    )

    print(response["data"] ?? "No data")
}

// MARK: - Error Handling Examples

/// Example 5: Proper Error Handling
func requestWithErrorHandling() async {
    let session = RestfulSession()

    do {
        let response = try await session.request(
            url: "https://api.example.com/data",
            method: "GET"
        )

        // Process successful response
        if let items = response["items"]?.arrayValue {
            print("Found \(items.count) items")
        }

    } catch RestfulError.invalidURL(let url) {
        print("Invalid URL: \(url)")

    } catch RestfulError.httpError(let statusCode, let data) {
        print("HTTP error \(statusCode)")
        if let errorMessage = String(data: data, encoding: .utf8) {
            print("Server message: \(errorMessage)")
        }

    } catch RestfulError.invalidResponseFormat {
        print("Response is not valid JSON")

    } catch RestfulError.decodingError(let error) {
        print("Failed to decode response: \(error)")

    } catch {
        print("Unexpected error: \(error)")
    }
}

// MARK: - Advanced Usage Examples

/// Example 6: PUT Request to Update Resource
func updateResource(id: Int) async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.example.com/users/\(id)",
        method: "PUT",
        body: [
            "name": "Jane Doe",
            "email": "jane@example.com",
        ],
        headers: [
            "Authorization": "Bearer YOUR_TOKEN"
        ]
    )

    print("Updated user:", response)
}

/// Example 7: DELETE Request
func deleteResource(id: Int) async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.example.com/users/\(id)",
        method: "DELETE",
        headers: [
            "Authorization": "Bearer YOUR_TOKEN"
        ]
    )

    print("Delete response:", response)
}

/// Example 8: PATCH Request for Partial Update
func partialUpdate(id: Int) async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.example.com/users/\(id)",
        method: "PATCH",
        body: [
            "email": "newemail@example.com"
        ],
        headers: [
            "Authorization": "Bearer YOUR_TOKEN"
        ]
    )

    print("Patched user:", response)
}

// MARK: - Real-World API Examples

/// Example 9: GitHub API Request
func fetchGitHubUser(username: String) async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://api.github.com/users/\(username)",
        method: "GET",
        headers: [
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "RestfulApp/1.0",
        ]
    )

    if let name = response["name"]?.stringValue,
        let publicRepos = response["public_repos"]?.intValue
    {
        print("\(name) has \(publicRepos) public repositories")
    }
}

/// Example 10: JSONPlaceholder API Request
func createPost(title: String, body: String) async throws {
    let session = RestfulSession()

    let response = try await session.request(
        url: "https://jsonplaceholder.typicode.com/posts",
        method: "POST",
        body: [
            "title": JSONValue.string(title),
            "body": JSONValue.string(body),
            "userId": 1,
        ]
    )

    if let postId = response["id"]?.intValue {
        print("Created post with ID: \(postId)")
    }
}

// MARK: - Custom Configuration Examples

/// Example 11: Using Custom URLSession Configuration
func customSessionConfiguration() async throws {
    // Create a custom configuration
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    config.httpMaximumConnectionsPerHost = 5

    // Create URLSession with custom config
    let urlSession = URLSession(configuration: config)

    // Create RestfulSession with custom URLSession
    let session = RestfulSession(urlSession: urlSession)

    let response = try await session.request(
        url: "https://api.example.com/data",
        method: "GET"
    )

    print("Response:", response)
}

/// Example 12: Multiple Sequential Requests
func multipleRequests() async throws {
    let session = RestfulSession()

    // First request - get user
    let user = try await session.request(
        url: "https://api.example.com/users/1",
        method: "GET"
    )

    // Second request - get user's posts
    if let userId = user["id"]?.intValue {
        let posts = try await session.request(
            url: "https://api.example.com/users/\(userId)/posts",
            method: "GET"
        )
        print("User posts:", posts)
    }
}

/// Example 13: Nested JSON Body
func complexBodyRequest() async throws {
    let session = RestfulSession()

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
            "currency": "USD",
        ],
        headers: [
            "Authorization": "Bearer YOUR_TOKEN"
        ]
    )

    print("Order created:", response)
}

// MARK: - Helper Functions

/// Example 14: Wrapper Function for API Calls
func callAPI<T>(
    url: String,
    method: String = "GET",
    body: [String: JSONValue]? = nil,
    headers: [String: String]? = nil,
    transform: ([String: JSONValue]) throws -> T
) async throws -> T {
    let session = RestfulSession()

    let response = try await session.request(
        url: url,
        method: method,
        body: body,
        headers: headers
    )

    return try transform(response)
}

// Usage of helper function
func useHelperFunction() async throws {
    let userName: String = try await callAPI(
        url: "https://api.example.com/users/1",
        method: "GET"
    ) { response in
        guard let name = response["name"]?.stringValue else {
            throw NSError(domain: "ParsingError", code: 1, userInfo: nil)
        }
        return name
    }

    print("User name:", userName)
}
