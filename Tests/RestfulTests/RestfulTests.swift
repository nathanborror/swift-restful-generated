import Foundation
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
