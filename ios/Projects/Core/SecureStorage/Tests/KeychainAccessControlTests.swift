import XCTest
import Foundation
import Security
@testable import CoreSecureStorage

final class KeychainAccessControlTests: XCTestCase {
    private var service: String!
    private var storage: KeychainSecureStorage!
    private let item = KeychainItemDescriptor(key: "test.secret", accessControlFlags: .biometryCurrentSet)

    override func setUp() {
        super.setUp()
        service = "tests.\(UUID().uuidString)"
        storage = KeychainSecureStorage(service: service)
        addTeardownBlock { [storage, item] in
            try? storage?.delete(for: item)
        }
    }

    func test_save_withBiometryAccessControl_succeeds() throws {
        // `SecItemAdd` itself does not require biometry — only reading the data does — so
        // saving a biometry-gated item is safe to assert in CI.
        XCTAssertNoThrow(try storage.save(Data("correct-horse".utf8), for: item))
    }

    func test_savedItem_carriesAccessControl_withoutAuthentication() throws {
        try storage.save(Data("correct-horse".utf8), for: item)

        // An attributes-only query (no `kSecReturnData`) does not trigger LAContext
        // evaluation, so it confirms the ACL was attached without needing Face ID.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service!,
            kSecAttrAccount as String: item.key,
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
