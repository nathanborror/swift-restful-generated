# Restful

An API agnostic way to interact with REST interfaces.

## Example Usage

```swift
import Restful

let session = RestfulSession()

let response = try await session.request(
    url: "https://api/openai.com/v1/responses",
    method: "POST",
    body: [
        "model": "gpt-4o-mini",
        "input": "Hello, World!",
    ],
    headers: [
        "Authentication": "Bearer API_TOKEN",
        "Content-Type": "application/json",
    ]
)

print(response["data"])
```
