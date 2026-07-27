import CoreDesignSystem
import SwiftUI

public struct SecretView: View {
    @Bindable var viewModel: SecretViewModel

    public init(viewModel: SecretViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "faceid")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent)

            Text("Protected secret")
                .font(.title2.bold())

            Text("This value is fetched from the backend, saved in the Keychain behind biometric access control, then read back with Face ID / Touch ID.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let revealedSecret = viewModel.revealedSecret {
                Text(revealedSecret)
                    .font(.title3.monospaced().bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.reveal() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text(viewModel.revealedSecret == nil ? "Reveal with Face ID" : "Reveal again")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
            .disabled(viewModel.isLoading)
        }
        .padding()
    }
}

#if DEBUG
import CoreModels

private struct PreviewFetchSecretUseCase: FetchSecretUseCaseProtocol {
    var result: Result<String, SecretError> = .success("correct-horse-battery-staple")

    func execute() async throws(SecretError) -> String {
        switch result {
        case .success(let secret): return secret
        case .failure(let error): throw error
        }
    }
}

#Preview("Idle") {
    SecretView(
        viewModel: SecretViewModel(
            fetchSecretUseCase: PreviewFetchSecretUseCase(),
            store: { _ in },
            unlock: { "correct-horse-battery-staple" }
        )
    )
}

#Preview("Revealed") {
    let viewModel = SecretViewModel(
        fetchSecretUseCase: PreviewFetchSecretUseCase(),
        store: { _ in },
        unlock: { "correct-horse-battery-staple" }
    )
    return SecretView(viewModel: viewModel)
        .task { await viewModel.reveal() }
}
#endif
