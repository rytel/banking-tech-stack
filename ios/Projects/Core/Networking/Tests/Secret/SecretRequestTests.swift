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

    func test_execute_on401_refreshesTokenAndRetriesWithNewBearerHeader() async throws {
        let callCounter = CallCounter()
        let capturedTokens = CapturedTokens()
        MockURLProtocol.handler = { request in
            capturedTokens.append(request.value(forHTTPHeaderField: "Authorization"))
            if callCounter.next() == 1 {
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                return (response, Data(#"{"error": "unauthorized"}"#.utf8))
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"secret": "shh"}"#.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let currentToken = MutableToken(initial: "expired-token")
        let repository = SecretRepository(
            urlSession: MockURLProtocol.session(),
            accessTokenProvider: { currentToken.value },
            tokenRefresher: {
                currentToken.value = "fresh-token"
                return true
            }
        )

        let secret = try await repository.fetchSecret()

        XCTAssertEqual(secret, "shh")
        XCTAssertEqual(callCounter.count, 2)
        XCTAssertEqual(capturedTokens.values, ["Bearer expired-token", "Bearer fresh-token"])
    }

    func test_execute_on401_whenRefreshFails_surfacesUnauthorizedWithoutRetrying() async {
        let callCounter = CallCounter()
        MockURLProtocol.handler = { request in
            _ = callCounter.next()
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"error": "unauthorized"}"#.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let repository = SecretRepository(
            urlSession: MockURLProtocol.session(),
            accessTokenProvider: { "expired-token" },
            tokenRefresher: { false }
        )

        do {
            _ = try await repository.fetchSecret()
            XCTFail("Expected SecretError.unauthorized")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
        XCTAssertEqual(callCounter.count, 1)
    }

    func test_execute_on401_whenRetryAlso401s_doesNotLoopIndefinitely() async {
        let callCounter = CallCounter()
        MockURLProtocol.handler = { request in
            _ = callCounter.next()
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"error": "unauthorized"}"#.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let repository = SecretRepository(
            urlSession: MockURLProtocol.session(),
            accessTokenProvider: { "still-expired-token" },
            tokenRefresher: { true }
        )

        do {
            _ = try await repository.fetchSecret()
            XCTFail("Expected SecretError.unauthorized")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
        XCTAssertEqual(callCounter.count, 2)
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

/// Thread-safe counter used to script `MockURLProtocol`'s single static handler into returning
/// a different response on the Nth call (e.g. 401 first, then 200 on retry).
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _count
    }

    /// Increments and returns the new count.
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _count += 1
        return _count
    }
}

/// Thread-safe collector for the `Authorization` header seen on each call, so a test can assert
/// the exact sequence of tokens sent across an initial attempt and a post-refresh retry.
private final class CapturedTokens: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [String?] = []

    var values: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return _values
    }

    func append(_ value: String?) {
        lock.lock()
        defer { lock.unlock() }
        _values.append(value)
    }
}

/// Thread-safe box standing in for a token store: `tokenRefresher` mutates it, and the next call
/// to `accessTokenProvider` reads the updated value.
private final class MutableToken: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String

    init(initial: String) {
        self._value = initial
    }

    var value: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}
