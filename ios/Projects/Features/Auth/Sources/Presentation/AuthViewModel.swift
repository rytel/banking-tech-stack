import CoreModels
import Observation

@MainActor
@Observable
public final class AuthViewModel {
    public var username = ""
    public var password = ""
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public private(set) var isAuthenticated = false

    private let loginUseCase: LoginUseCaseProtocol
    private let onLoginSuccess: @Sendable (TokenPair) -> Void

    public init(
        loginUseCase: LoginUseCaseProtocol,
        onLoginSuccess: @escaping @Sendable (TokenPair) -> Void = { _ in }
    ) {
        self.loginUseCase = loginUseCase
        self.onLoginSuccess = onLoginSuccess
    }

    public func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let tokens = try await loginUseCase.execute(username: username, password: password)
            onLoginSuccess(tokens)
            isAuthenticated = true
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: AuthError) -> String? {
        switch error {
        case .invalidCredentials: return "Invalid username or password."
        case .offline: return "No internet connection."
        case .serverUnavailable: return "Server is unavailable. Try again later."
        case .sessionExpired, .invalidData, .unknown: return "Something went wrong. Try again."
        case .cancelled: return nil
        }
    }
}
