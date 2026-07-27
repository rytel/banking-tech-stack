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
    private let onLoginSuccess: @Sendable (TokenPair) async -> Void
    private let onLogout: @Sendable () async -> Void

    public init(
        loginUseCase: LoginUseCaseProtocol,
        onLoginSuccess: @escaping @Sendable (TokenPair) async -> Void = { _ in },
        onLogout: @escaping @Sendable () async -> Void = {}
    ) {
        self.loginUseCase = loginUseCase
        self.onLoginSuccess = onLoginSuccess
        self.onLogout = onLogout
    }

    public func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let tokens = try await loginUseCase.execute(username: username, password: password)
            await onLoginSuccess(tokens)
            isAuthenticated = true
        } catch {
            errorMessage = message(for: error)
        }
    }

    public func logout() async {
        await onLogout()
        username = ""
        password = ""
        errorMessage = nil
        isAuthenticated = false
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
