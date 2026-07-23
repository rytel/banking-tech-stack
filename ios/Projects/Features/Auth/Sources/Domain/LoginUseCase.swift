import CoreModels

public protocol LoginUseCaseProtocol: Sendable {
    func execute(username: String, password: String) async throws(AuthError) -> TokenPair
}

public final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(username: String, password: String) async throws(AuthError) -> TokenPair {
        try await repository.login(username: username, password: password)
    }
}
