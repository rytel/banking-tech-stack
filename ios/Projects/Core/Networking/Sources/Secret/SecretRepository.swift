import Foundation
import CoreModels

public final class SecretRepository: SecretRepositoryProtocol {
    private let httpClient: HTTPClient

    public init(
        environment: APIEnvironment = .local,
        urlSession: URLSession = .shared,
        accessTokenProvider: @escaping @Sendable () async -> String? = { nil },
        tokenRefresher: @escaping @Sendable () async -> Bool = { false }
    ) {
        self.httpClient = HTTPClient(
            environment: environment,
            urlSession: urlSession,
            accessTokenProvider: accessTokenProvider,
            tokenRefresher: tokenRefresher
        )
    }

    public func fetchSecret() async throws(SecretError) -> String {
        do {
            return try await httpClient.execute(SecretAPI.secret()).secret
        } catch {
            throw SecretError(error)
        }
    }
}
