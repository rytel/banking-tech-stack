/// Domain-level errors for the topics area.
/// On purpose this is NOT `LocalizedError`: a domain error carries meaning,
/// not UI text. The presentation layer decides how to show each case.
public enum TopicsError: Error, Equatable, Sendable {
    case offline
    case unauthorized
    case topicNotFound
    case serverUnavailable
    case invalidData
    /// Typed throws cannot pass `CancellationError` through, so cancellation
    /// is an explicit case. Callers must ignore it instead of showing an alert.
    case cancelled
    case unknown
}
