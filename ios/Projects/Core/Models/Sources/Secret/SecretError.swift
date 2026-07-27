/// Domain-level errors for the protected `/secret` endpoint.
public enum SecretError: Error, Equatable, Sendable {
    case offline
    case unauthorized
    case serverUnavailable
    case invalidData
    /// Typed throws cannot pass `CancellationError` through, so cancellation
    /// is an explicit case. Callers must ignore it instead of showing an alert.
    case cancelled
    case unknown
}
