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
