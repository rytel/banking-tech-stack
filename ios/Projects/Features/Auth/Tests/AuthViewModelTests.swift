import Testing
import CoreModels
@testable import FeatureAuth

private struct StubLoginUseCase: LoginUseCaseProtocol {
    var result: Result<TokenPair, AuthError>

    func execute(username: String, password: String) async throws(AuthError) -> TokenPair {
        switch result {
        case .success(let token): return token
        case .failure(let error): throw error
        }
    }
}

@MainActor
struct AuthViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = AuthViewModel(loginUseCase: StubLoginUseCase(result: .failure(.unknown)))
        #expect(Bool(true))
    }

    @Test func successfulLoginSetsIsAuthenticated() async {
        let token = TokenPair(accessToken: "a", refreshToken: "r", expiresIn: 3600)
        let viewModel = AuthViewModel(loginUseCase: StubLoginUseCase(result: .success(token)))

        await viewModel.login()

        #expect(viewModel.isAuthenticated)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func failedLoginSetsErrorMessage() async {
        let viewModel = AuthViewModel(loginUseCase: StubLoginUseCase(result: .failure(.invalidCredentials)))

        await viewModel.login()

        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.errorMessage != nil)
    }
}
