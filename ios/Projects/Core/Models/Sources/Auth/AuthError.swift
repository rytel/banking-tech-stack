/// Domain-level errors for authentication.
/// On purpose this is NOT `LocalizedError`: a domain error carries meaning,
/// not UI text. The presentation layer decides how to show each case.
public enum AuthError: Error, Equatable, Sendable {
    /// The same transport 401 maps to different domain meanings:
    /// during login it means wrong credentials...
    case invalidCredentials
    /// ...but during a token refresh it means the session ended.
    case sessionExpired
    case offline
    case serverUnavailable
    case invalidData
    /// Typed throws cannot pass `CancellationError` through, so cancellation
    /// is an explicit case. Callers must ignore it instead of showing an alert.
    case cancelled
    case unknown
}
