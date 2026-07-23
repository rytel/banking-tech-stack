import Foundation
import CoreModels

public final class AuthRepository: AuthRepositoryProtocol {
    private let httpClient: HTTPClient

    public init(environment: APIEnvironment = .local, urlSession: URLSession = .shared) {
        self.httpClient = HTTPClient(environment: environment, urlSession: urlSession)
    }

    public func login(username: String, password: String) async throws(AuthError) -> TokenPair {
        do {
            return try await httpClient.execute(AuthAPI.login(username: username, password: password))
        } catch {
            throw AuthError(error, on401: .invalidCredentials)
        }
    }

    public func refresh(refreshToken: String) async throws(AuthError) -> TokenPair {
        do {
            return try await httpClient.execute(AuthAPI.refresh(token: refreshToken))
        } catch {
            throw AuthError(error, on401: .sessionExpired)
        }
    }
}
