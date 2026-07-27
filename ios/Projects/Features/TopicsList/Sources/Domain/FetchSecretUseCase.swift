import CoreModels

public protocol FetchSecretUseCaseProtocol: Sendable {
    func execute() async throws(SecretError) -> String
}

public final class FetchSecretUseCase: FetchSecretUseCaseProtocol {
    private let repository: SecretRepositoryProtocol

    public init(repository: SecretRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws(SecretError) -> String {
        try await repository.fetchSecret()
    }
}
