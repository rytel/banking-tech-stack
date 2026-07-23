public protocol AccessTokenStoring: Sendable {
    func set(_ token: String?) async
    func currentToken() async -> String?
}

/// The access token is short-TTL, in-memory-only shared mutable state that will eventually
/// be read from more than one isolation domain (UI on `@MainActor`, and later an HTTP
/// interceptor attaching the `Authorization` header from a background context). An `actor`
/// gives the compiler-checked exclusive access Swift 6 strict concurrency wants, matching
/// this repo's actor-first approach, instead of a hand-rolled `NSLock`.
public actor AccessTokenStore: AccessTokenStoring {
    private var token: String?

    public init() {}

    public func set(_ token: String?) {
        self.token = token
    }

    public func currentToken() -> String? {
        token
    }
}
