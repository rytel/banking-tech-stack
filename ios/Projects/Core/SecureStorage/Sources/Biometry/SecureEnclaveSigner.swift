import CryptoKit
import Foundation
import LocalAuthentication
import Security

public enum SecureEnclaveSigningError: Error, Equatable, Sendable {
    case unavailable
    case keyGenerationFailed
    case invalidKeyData
    case authenticationFailed
    case storage(KeychainError)
}

public protocol SigningProtocol: Sendable {
    var isAvailable: Bool { get }
    func publicKey() throws(SecureEnclaveSigningError) -> P256.Signing.PublicKey
    func sign(_ data: Data, reason: String) async throws(SecureEnclaveSigningError) -> P256.Signing.ECDSASignature
}

/// Signs data with a P-256 key that never leaves the Secure Enclave. The private key's
/// `dataRepresentation` (an opaque blob, useless outside this device's enclave) is persisted
/// as a plain Keychain item — no ACL on the item itself. Biometric gating instead lives in the
/// `SecAccessControl` baked into the enclave key at generation time (`.privateKeyUsage` +
/// `.biometryCurrentSet`): reconstructing the key with an `LAContext` is what actually pumps
/// the Face ID / Touch ID UI, matching `KeychainSecretStore`'s use of the same mechanism.
public final class SecureEnclaveSigner: SigningProtocol {
    private let storage: SecureStorageProtocol
    private let privateKeyItem: KeychainItemDescriptor
    private let publicKeyItem: KeychainItemDescriptor
    private let contextProvider: @Sendable () -> LAContext

    public init(
        storage: SecureStorageProtocol = KeychainSecureStorage(),
        keyPrefix: String = "auth.signingKey",
        contextProvider: @escaping @Sendable () -> LAContext = { LAContext() }
    ) {
        self.storage = storage
        self.privateKeyItem = KeychainItemDescriptor(key: "\(keyPrefix).private")
        self.publicKeyItem = KeychainItemDescriptor(key: "\(keyPrefix).public")
        self.contextProvider = contextProvider
    }

    public var isAvailable: Bool {
        SecureEnclave.isAvailable
    }

    public func publicKey() throws(SecureEnclaveSigningError) -> P256.Signing.PublicKey {
        try generateKeyIfNeeded()

        guard let data = try mapStorage({ () throws(KeychainError) in try storage.read(for: publicKeyItem) }) else {
            throw .keyGenerationFailed
        }
        guard let publicKey = try? P256.Signing.PublicKey(rawRepresentation: data) else {
            throw .invalidKeyData
        }
        return publicKey
    }

    public func sign(
        _ data: Data,
        reason: String
    ) async throws(SecureEnclaveSigningError) -> P256.Signing.ECDSASignature {
        try generateKeyIfNeeded()

        guard let keyData = try mapStorage({ () throws(KeychainError) in try storage.read(for: privateKeyItem) }) else {
            throw .keyGenerationFailed
        }

        let contextProvider = self.contextProvider

        // Reconstructing the enclave key with an `authenticationContext` blocks while the
        // system Face ID / Touch ID UI is up, so run it off the caller's actor — see
        // `KeychainSecretStore.readSecret` for the same pattern.
        let outcome: Result<P256.Signing.ECDSASignature, SecureEnclaveSigningError> = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let context = contextProvider()
                context.localizedReason = reason
                let result = Result<P256.Signing.ECDSASignature, SecureEnclaveSigningError> { () throws(SecureEnclaveSigningError) in
                    do {
                        let privateKey = try SecureEnclave.P256.Signing.PrivateKey(
                            dataRepresentation: keyData,
                            authenticationContext: context
                        )
                        return try privateKey.signature(for: data)
                    } catch {
                        throw SecureEnclaveSigningError.authenticationFailed
                    }
                }
                continuation.resume(returning: result)
            }
        }

        return try outcome.get()
    }

    private func generateKeyIfNeeded() throws(SecureEnclaveSigningError) {
        if try mapStorage({ () throws(KeychainError) in try storage.read(for: publicKeyItem) }) != nil {
            return
        }

        guard isAvailable else {
            throw .unavailable
        }

        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet],
            &accessControlError
        ) else {
            throw .keyGenerationFailed
        }

        guard let privateKey = try? SecureEnclave.P256.Signing.PrivateKey(accessControl: accessControl) else {
            throw .keyGenerationFailed
        }

        try mapStorage { () throws(KeychainError) in try storage.save(privateKey.dataRepresentation, for: privateKeyItem) }
        try mapStorage { () throws(KeychainError) in try storage.save(privateKey.publicKey.rawRepresentation, for: publicKeyItem) }
    }

    private func mapStorage<T>(_ body: () throws(KeychainError) -> T) throws(SecureEnclaveSigningError) -> T {
        do throws(KeychainError) {
            return try body()
        } catch {
            throw .storage(error)
        }
    }
}
