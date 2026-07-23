import CoreModels

// `NetworkError` is a transport detail of this module, so the mapping to the
// public domain error lives here and stays internal. CoreModels keeps no
// dependency on networking.

extension TopicsError {
    init(_ networkError: NetworkError) {
        switch networkError {
        case .offline:
            self = .offline
        case .cancelled:
            self = .cancelled
        case .serverError(401, _):
            self = .unauthorized
        case .serverError(404, _):
            self = .topicNotFound
        case .serverError(500..<600, _):
            self = .serverUnavailable
        case .decodingError, .invalidResponse:
            self = .invalidData
        case .serverError, .invalidRequest, .transportError:
            self = .unknown
        }
    }
}
