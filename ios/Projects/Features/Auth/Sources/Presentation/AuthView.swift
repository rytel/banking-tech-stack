import CoreDesignSystem
import SwiftUI

public struct AuthView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Log in")
                .font(.largeTitle.bold())

            TextField("Username", text: $viewModel.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
            .disabled(viewModel.isLoading || viewModel.username.isEmpty || viewModel.password.isEmpty)
        }
        .padding()
    }
}

#if DEBUG
import CoreModels

private struct PreviewLoginUseCase: LoginUseCaseProtocol {
    var result: Result<TokenPair, AuthError> = .success(
        TokenPair(accessToken: "preview", refreshToken: "preview", expiresIn: 3600)
    )

    func execute(username: String, password: String) async throws(AuthError) -> TokenPair {
        switch result {
        case .success(let token): return token
        case .failure(let error): throw error
        }
    }
}

#Preview("Idle") {
    AuthView(viewModel: AuthViewModel(loginUseCase: PreviewLoginUseCase()))
}

#Preview("Error") {
    let viewModel = AuthViewModel(loginUseCase: PreviewLoginUseCase(result: .failure(.invalidCredentials)))
    viewModel.username = "demo"
    viewModel.password = "wrong-password"
    return AuthView(viewModel: viewModel)
        .task { await viewModel.login() }
}
#endif
