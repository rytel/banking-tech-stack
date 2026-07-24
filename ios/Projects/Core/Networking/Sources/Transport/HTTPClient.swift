import Foundation

/// A thin, generic layer over URLSession.
/// It only knows how to send a `Request` and decode its `Response`;
/// endpoint definitions live next to their own domain.
final class HTTPClient: Sendable {
    private let environment: APIEnvironment
    private let urlSession: URLSession

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(environment: APIEnvironment, urlSession: URLSession = .shared) {
        self.environment = environment
        self.urlSession = urlSession
    }

    func execute<Response>(_ request: Request<Response>) async throws(NetworkError) -> Response {
        let urlRequest = try urlRequest(for: request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch let urlError as URLError {
            // A rejected pin cancels the TLS handshake, and URLSession reports
            // that as a plain `.cancelled`. Ask the pinning delegate whether
            // this host just failed pinning, so the failure is not silent.
            if urlError.code == .cancelled,
                let delegate = urlSession.delegate as? PinningURLSessionDelegate,
                let host = urlRequest.url?.host,
                delegate.consumePinningFailure(forHost: host) {
                throw NetworkError.pinningFailure
            }
            throw NetworkError(urlError)
        } catch {
            throw NetworkError.transportError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage(from: data))
        }

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    func urlRequest<Response>(for request: Request<Response>) throws(NetworkError) -> URLRequest {
        var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        )
        if !request.queryItems.isEmpty {
            components?.queryItems = request.queryItems
        }
        guard let url = components?.url else {
            throw NetworkError.invalidRequest
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        if let body = request.body {
            do {
                urlRequest.httpBody = try Self.encoder.encode(body)
            } catch {
                throw NetworkError.invalidRequest
            }
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }

    private func errorMessage(from data: Data) -> String {
        struct ErrorResponse: Decodable {
            let error: String
        }
        return (try? Self.decoder.decode(ErrorResponse.self, from: data))?.error ?? "Request failed"
    }
}
