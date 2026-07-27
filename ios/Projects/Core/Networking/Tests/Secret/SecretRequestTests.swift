import XCTest
@testable import CoreNetworking

final class SecretRequestTests: XCTestCase {
    private let client = HTTPClient(environment: .local)

    func test_secretRepositoryConformsToProtocol() {
        _ = SecretRepository()
    }

    func test_secretRequest_targetsPathAndRequiresAuth() throws {
        let request = SecretAPI.secret()

        XCTAssertTrue(request.requiresAuth)

        let urlRequest = try client.urlRequest(for: request)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://localhost:8443/secret")
        XCTAssertEqual(urlRequest.httpMethod, "GET")
    }

    func test_execute_withAccessToken_attachesBearerHeader() async throws {
        let capturedRequest = CapturedRequest()
        MockURLProtocol.handler = { request in
            capturedRequest.set(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"secret": "shh"}"#.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let repository = SecretRepository(
            urlSession: MockURLProtocol.session(),
            accessTokenProvider: { "abc123" }
        )

        _ = try await repository.fetchSecret()

        XCTAssertEqual(capturedRequest.value?.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
    }

    func test_execute_withoutAccessToken_omitsAuthorizationHeader() async throws {
        let capturedRequest = CapturedRequest()
        MockURLProtocol.handler = { request in
            capturedRequest.set(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"secret": "shh"}"#.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let repository = SecretRepository(urlSession: MockURLProtocol.session())

        _ = try await repository.fetchSecret()

        XCTAssertNotNil(capturedRequest.value)
        XCTAssertNil(capturedRequest.value?.value(forHTTPHeaderField: "Authorization"))
    }
}

/// Thread-safe box so `MockURLProtocol`'s synchronous `@Sendable` handler can hand a captured
/// `URLRequest` back to the (already-finished) test body without tripping the "mutation of
/// captured var in concurrently-executing code" diagnostic that a plain `var` capture would.
private final class CapturedRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: URLRequest?

    var value: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func set(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        _value = request
    }
}
