import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A typed description of one API call.
/// `Response` is the model the backend returns, so the compiler
/// checks that every call is decoded into the right type.
struct Request<Response: Decodable & Sendable>: Sendable {
    let path: String
    let method: HTTPMethod
    var body: (any Encodable & Sendable)? = nil
    var queryItems: [URLQueryItem] = []
}

/// Transport-level errors, internal to this module. Repositories map them
/// to public domain errors (`TopicsError`, `AuthError`) before they leave.
enum NetworkError: Error, Equatable, Sendable {
    case invalidRequest
    case invalidResponse
    case offline
    case cancelled
    case pinningFailure
    case decodingError(String)
    case serverError(Int, String)
    case transportError(String)
}

extension NetworkError {
    /// Normalizes raw `URLSession` failures into our own cases, so nothing
    /// above the transport layer ever sees a `URLError`.
    init(_ urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            self = .offline
        case .cancelled:
            self = .cancelled
        case .serverCertificateUntrusted, .secureConnectionFailed, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            // TLS-level failures. Note: a cancel from the pinning delegate is
            // reported as `.cancelled`, not as one of these codes — that case
            // is detected in `HTTPClient` by asking the delegate directly.
            self = .pinningFailure
        default:
            self = .transportError(urlError.localizedDescription)
        }
    }
}
