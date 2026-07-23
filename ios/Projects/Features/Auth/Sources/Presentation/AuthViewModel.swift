import Observation

@MainActor
@Observable
public final class AuthViewModel {
    private let loginUseCase: LoginUseCaseProtocol

    public init(loginUseCase: LoginUseCaseProtocol) {
        self.loginUseCase = loginUseCase
    }
}
