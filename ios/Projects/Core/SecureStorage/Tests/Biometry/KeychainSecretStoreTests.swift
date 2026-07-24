import XCTest
import Foundation
import Security
@testable import CoreSecureStorage

/// Only `save` and the attribute-only ACL check are exercised: the authenticated
/// `readSecret` path pumps the Face ID / Touch ID UI, which cannot be driven from XCTest.
final class KeychainSecretStoreTests: XCTestCase {
    private var service: String!
    private var storage: KeychainSecureStorage!
    private var secretStore: KeychainSecretStore!
    private let key = "test.secret"

    override func setUp() {
        super.setUp()
        service = "tests.\(UUID().uuidString)"
        storage = KeychainSecureStorage(service: service)
        secretStore = KeychainSecretStore(storage: storage, key: key)
        let descriptor = KeychainItemDescriptor(key: key, accessControlFlags: .biometryCurrentSet)
        addTeardownBlock { [storage, descriptor] in
            try? storage?.delete(for: descriptor)
        }
    }

    func test_save_succeeds() {
        XCTAssertNoThrow(try secretStore.save("correct-horse-battery-staple"))
    }

    func test_savedSecret_isBiometryGated() throws {
        try secretStore.save("correct-horse-battery-staple")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service!,
            kSecAttrAccount as String: key,
            kSecReturnAttributes as String: true,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        XCTAssertEqual(status, errSecSuccess)
        let attributes = try XCTUnwrap(result as? [String: Any])
        XCTAssertNotNil(attributes[kSecAttrAccessControl as String])
    }
}
