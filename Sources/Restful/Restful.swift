import Foundation
import JSONSchema

/// A session for making RESTful API requests
public class RestfulSession {
    private let urlSession: URLSession

    /// Initialize a new RestfulSession
    /// - Parameter urlSession: The URLSession to use for requests. Defaults to `.shared`
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Make a REST API request
    /// - Parameters:
    ///   - url: The URL string for the request
    ///   - method: The HTTP method (GET, POST, PUT, DELETE, etc.)
    ///   - body: Optional request body as a dictionary
    ///   - headers: Optional HTTP headers as a dictionary
    /// - Returns: The response as a dictionary
    /// - Throws: RestfulError if the request fails
    public func request(
        url urlString: String,
        method: String,
        body: [String: JSONValue]? = nil,
        headers: [String: String]? = nil
    ) async throws -> [String: JSONValue] {
        // Create URL
        guard let url = URL(string: urlString) else {
            throw RestfulError.invalidURL(urlString)
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Set headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Set body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(body)
                // Set content-type if not already set
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                throw RestfulError.invalidBody(error)
            }
        }

        // Perform request
        let (data, response) = try await urlSession.data(for: request)

        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RestfulError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to decode error response as JSON
            if let jsonError = try? JSONDecoder().decode([String: JSONValue].self, from: data) {
                throw RestfulError.httpErrorJSON(
                    statusCode: httpResponse.statusCode, data: jsonError)
            } else {
                throw RestfulError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
        }

        // Parse JSON response
        do {
            let decoder = JSONDecoder()
            let json = try decoder.decode([String: JSONValue].self, from: data)
            return json
        } catch {
            throw RestfulError.decodingError(error)
        }
    }
}

/// Errors that can occur during RESTful requests
public enum RestfulError: Error, LocalizedError {
    case invalidURL(String)
    case invalidBody(Error)
    case invalidResponse
    case invalidResponseFormat
    case httpError(statusCode: Int, data: Data)
    case httpErrorJSON(statusCode: Int, data: [String: JSONValue])
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidBody(let error):
            return "Invalid request body: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .invalidResponseFormat:
            return "Response is not a valid JSON object"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .httpErrorJSON(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Key-Path Traversal Extension

extension Dictionary where Key == String, Value == JSONValue {
    /// Access nested JSON values using dot notation and array indices
    ///
    /// Example usage:
    /// ```
    /// response["user.name"]           // Access nested object
    /// response["items.0.title"]       // Access first array element
    /// response["data.results.0.id"]   // Mixed nesting
    /// ```
    ///
    /// - Parameter keyPath: A dot-separated path to the desired value.
    ///   Use numeric indices for array access (e.g., "items.0")
    /// - Returns: The JSONValue at the specified path, or nil if not found
    public subscript(keyPath keyPath: String) -> JSONValue? {
        let components = keyPath.split(separator: ".").map(String.init)
        var current: JSONValue? = nil

        // Start with the root dictionary
        guard let firstKey = components.first else {
            return nil
        }

        current = self[firstKey]

        // Traverse remaining components
        for component in components.dropFirst() {
            guard let currentValue = current else {
                return nil
            }

            // Check if component is a numeric index for array access
            if let index = Int(component) {
                guard let array = currentValue.arrayValue,
                    index >= 0,
                    index < array.count
                else {
                    return nil
                }
                current = array[index]
            } else {
                // Object key access
                guard let object = currentValue.objectValue else {
                    return nil
                }
                current = object[component]
            }
        }

        return current
    }
}
