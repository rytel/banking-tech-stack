/// Domain-level errors for the live ticker stream.
/// On purpose this is NOT `LocalizedError`: a domain error carries meaning,
/// not UI text. The presentation layer decides how to show each case.
public enum TickerError: Error, Equatable, Sendable {
    case offline
    case connectionFailed
    case decodingError
    /// The stream ended because the subscriber cancelled it, not because
    /// of a real failure. Callers must ignore it instead of showing an alert.
    case cancelled
    case unknown
}
