import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    private let loginUseCase: LoginUseCaseProtocol

    public init(loginUseCase: LoginUseCaseProtocol) {
        self.loginUseCase = loginUseCase
    }
}
