import Foundation
import CoreModels

public final class AuthRepository: AuthRepositoryProtocol {
    private let httpClient: HTTPClient

    public init(environment: APIEnvironment = .local) {
        self.httpClient = HTTPClient(environment: environment)
    }

    public func login(username: String, password: String) async throws -> TokenPair {
        try await httpClient.execute(AuthAPI.login(username: username, password: password))
    }

    public func refresh(refreshToken: String) async throws -> TokenPair {
        try await httpClient.execute(AuthAPI.refresh(token: refreshToken))
    }
}
