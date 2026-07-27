import Foundation

extension URLSession {
    /// A session whose TLS connections are SPKI-pinned for `environment`.
    /// The composition root builds one of these and injects it into every
    /// repository, so all HTTP and WebSocket traffic goes through the same
    /// pinning delegate.
    ///
    /// Uses `.ephemeral` rather than `.default`: `.default` backs responses
    /// with a disk-persisted `URLCache`, which would write banking API
    /// responses (tokens, account data) to disk outside the Keychain.
    /// `.ephemeral` keeps everything in memory only, for the lifetime of
    /// the session.
    public static func pinned(for environment: APIEnvironment) -> URLSession {
        URLSession(
            configuration: .ephemeral,
            delegate: PinningURLSessionDelegate(configuration: environment.pinningConfiguration),
            delegateQueue: nil
        )
    }
}
