import CoreModels

// `NetworkError` is a transport detail of this module, so the mapping to the
// public domain error lives here and stays internal. CoreModels keeps no
// dependency on networking.

extension AuthError {
    /// The same transport 401 means different things per operation, so the
    /// caller names its domain meaning through `on401`.
    init(_ networkError: NetworkError, on401: AuthError) {
        switch networkError {
        case .offline:
            self = .offline
        case .cancelled:
            self = .cancelled
        case .serverError(401, _):
            self = on401
        case .serverError(500..<600, _):
            self = .serverUnavailable
        case .decodingError, .invalidResponse:
            self = .invalidData
        case .serverError, .invalidRequest, .transportError, .pinningFailure:
            self = .unknown
        }
    }
}
