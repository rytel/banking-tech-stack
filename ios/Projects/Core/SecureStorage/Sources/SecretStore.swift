import Foundation
import LocalAuthentication

public protocol SecretStoring: Sendable {
    func save(_ secret: String) throws(KeychainError)
    func readSecret(reason: String) async throws(KeychainError) -> String
}

/// Stores the `GET /secret` value behind biometric access control: a read triggers Face ID /
/// Touch ID. The capability is complete and tested, but deliberately not wired into any view
/// model — it's a ready-to-use store, not a screen.
public final class KeychainSecretStore: SecretStoring {
    private let storage: SecureStorageProtocol
    private let item: KeychainItemDescriptor
    private let contextProvider: @Sendable () -> LAContext

    public init(
        storage: SecureStorageProtocol = KeychainSecureStorage(),
        key: String = "auth.secret",
        contextProvider: @escaping @Sendable () -> LAContext = { LAContext() }
    ) {
        self.storage = storage
        self.item = KeychainItemDescriptor(key: key, accessControlFlags: .biometryCurrentSet)
        self.contextProvider = contextProvider
    }

    public func save(_ secret: String) throws(KeychainError) {
        try storage.save(Data(secret.utf8), for: item)
    }

    public func readSecret(reason: String) async throws(KeychainError) -> String {
        let storage = self.storage
        let item = self.item
        let contextProvider = self.contextProvider

        // `SecItemCopyMatching` blocks while the system Face ID / Touch ID UI is up, so run it
        // on a background queue — not on the caller (e.g. a `@MainActor` view model) and not on
        // a cooperative thread-pool thread — for the whole duration of the prompt.
        let outcome: Result<Data?, KeychainError> = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let context = contextProvider()
                context.localizedReason = reason
                // `Result(catching:)` keeps the typed `KeychainError` across the queue hop —
                // a plain `Task`/`throws` boundary would widen it to `any Error`.
                let result = Result<Data?, KeychainError> { () throws(KeychainError) in
                    try storage.read(for: item, context: context)
                }
                continuation.resume(returning: result)
            }
        }

        let data = try outcome.get()
        guard let data else {
            throw KeychainError.itemNotFound
        }
        guard let secret = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return secret
    }
}
