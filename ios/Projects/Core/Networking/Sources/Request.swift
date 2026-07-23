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

enum NetworkError: LocalizedError, Sendable {
    case invalidRequest
    case invalidResponse
    case decodingError(String)
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "Could not build a valid request URL"
        case .invalidResponse: "Invalid response from server"
        case .decodingError(let message): "Decoding error: \(message)"
        case .serverError(let code, let message): "Server error (\(code)): \(message)"
        }
    }
}
