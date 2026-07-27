import CoreModels
import Observation

/// Fetches the protected `/secret` value, saves it behind biometric access
/// control, then immediately reads it back — so `reveal()` demonstrates the
/// full round trip: backend call, Keychain write, and a Face ID/Touch ID
/// gated Keychain read. The store/unlock closures keep this feature module
/// free of a direct dependency on `CoreSecureStorage`, the same pattern
/// `AuthViewModel.onLoginSuccess` uses.
@MainActor
@Observable
public final class SecretViewModel {
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public private(set) var revealedSecret: String?

    private let fetchSecretUseCase: FetchSecretUseCaseProtocol
    private let store: @Sendable (String) async -> Void
    private let unlock: @Sendable () async -> String?

    public init(
        fetchSecretUseCase: FetchSecretUseCaseProtocol,
        store: @escaping @Sendable (String) async -> Void,
        unlock: @escaping @Sendable () async -> String?
    ) {
        self.fetchSecretUseCase = fetchSecretUseCase
        self.store = store
        self.unlock = unlock
    }

    public func reveal() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let secret = try await fetchSecretUseCase.execute()
            await store(secret)
            guard let unlocked = await unlock() else {
                errorMessage = "Biometric unlock failed or was cancelled."
                return
            }
            revealedSecret = unlocked
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: SecretError) -> String? {
        switch error {
        case .offline: return "No internet connection."
        case .unauthorized: return "You need to log in again."
        case .serverUnavailable: return "Server is unavailable. Try again later."
        case .invalidData, .unknown: return "Something went wrong. Try again."
        case .cancelled: return nil
        }
    }
}
