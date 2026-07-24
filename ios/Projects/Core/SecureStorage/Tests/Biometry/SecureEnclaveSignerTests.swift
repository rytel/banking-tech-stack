import XCTest
import CryptoKit
@testable import CoreSecureStorage

/// Only key generation and persistence of the public key are exercised: reconstructing the
/// private key for `sign(_:reason:)` pumps the Face ID / Touch ID UI, which cannot be driven
/// from XCTest (same limitation as `KeychainSecretStoreTests`).
///
/// `SecureEnclave.isAvailable` alone isn't a reliable gate here: on an Apple Silicon host it
/// reports `true` for the Simulator too, but actually generating a key with a
/// `.biometryCurrentSet` access control still fails there with a LocalAuthentication error
/// ("This call is not supported on iOS Simulator"). So the skip is based on an actual
/// generation attempt, not just the availability flag.
final class SecureEnclaveSignerTests: XCTestCase {
    private var service: String!
    private var storage: KeychainSecureStorage!
    private var keyPrefix: String!
    private var signer: SecureEnclaveSigner!

    override func setUpWithError() throws {
        try super.setUpWithError()
        service = "tests.\(UUID().uuidString)"
        keyPrefix = "test.signingKey"
        storage = KeychainSecureStorage(service: service)
        signer = SecureEnclaveSigner(storage: storage, keyPrefix: keyPrefix)

        addTeardownBlock { [storage, keyPrefix] in
            try? storage?.delete(for: KeychainItemDescriptor(key: "\(keyPrefix!).private"))
            try? storage?.delete(for: KeychainItemDescriptor(key: "\(keyPrefix!).public"))
        }

        do {
            _ = try signer.publicKey()
        } catch {
            throw XCTSkip("Secure Enclave key generation is not usable in this environment: \(error)")
        }
    }

    func test_publicKey_generatesAndPersistsAKey() throws {
        let publicKey = try signer.publicKey()

        let stored = try storage.read(for: KeychainItemDescriptor(key: "\(keyPrefix!).public"))
        XCTAssertEqual(stored, publicKey.rawRepresentation)
    }

    func test_publicKey_isStableAcrossCalls() throws {
        let first = try signer.publicKey()
        let second = try signer.publicKey()

        XCTAssertEqual(first.rawRepresentation, second.rawRepresentation)
    }

    func test_publicKey_isStableAcrossSignerInstances() throws {
        let first = try signer.publicKey()

        let otherSigner = SecureEnclaveSigner(storage: storage, keyPrefix: keyPrefix)
        let second = try otherSigner.publicKey()

        XCTAssertEqual(first.rawRepresentation, second.rawRepresentation)
    }
}
