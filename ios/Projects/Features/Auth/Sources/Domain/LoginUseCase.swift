import CoreModels

public protocol LoginUseCaseProtocol {
    // Day 4: func execute(username: String, password: String) async throws
}

public final class LoginUseCase: LoginUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }
}
