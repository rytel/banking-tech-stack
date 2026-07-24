import Foundation

extension URLSession {
    /// A session whose TLS connections are SPKI-pinned for `environment`.
    /// The composition root builds one of these and injects it into every
    /// repository, so all HTTP and WebSocket traffic goes through the same
    /// pinning delegate.
    public static func pinned(for environment: APIEnvironment) -> URLSession {
        URLSession(
            configuration: .default,
            delegate: PinningURLSessionDelegate(configuration: environment.pinningConfiguration),
            delegateQueue: nil
        )
    }
}
