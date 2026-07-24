import Foundation
import Security
import LocalAuthentication

public protocol SecureStorageProtocol: Sendable {
    func save(_ data: Data, for item: KeychainItemDescriptor) throws(KeychainError)
    func read(for item: KeychainItemDescriptor, context: LAContext?) throws(KeychainError) -> Data?
    func delete(for item: KeychainItemDescriptor) throws(KeychainError)
}

public extension SecureStorageProtocol {
    func read(for item: KeychainItemDescriptor) throws(KeychainError) -> Data? {
        try read(for: item, context: nil)
    }
}

/// A thin, hand-rolled wrapper over the raw Security framework Keychain API
/// (`SecItemAdd`/`SecItemCopyMatching`/`SecItemUpdate`/`SecItemDelete`) — no third-party
/// dependency, on purpose.
public final class KeychainSecureStorage: SecureStorageProtocol {
    private let service: String

    /// `service` (-> `kSecAttrService`) is an init-time parameter, not a per-call one, so
    /// tests can pass a unique service string and never collide with real app data or
    /// with each other, and can clean up in `tearDown`.
    public init(service: String = "dev.rflrytel.bankingtechstack.securestorage") {
        self.service = service
    }

    public func save(_ data: Data, for item: KeychainItemDescriptor) throws(KeychainError) {
        var query = searchQuery(for: item)
        query[kSecValueData as String] = data

        // `kSecAttrAccessible` and `kSecAttrAccessControl` are mutually exclusive:
        // the ACL already encodes an accessibility internally, so when an ACL is
        // present the plain accessibility attribute must be omitted.
        if let flag = item.accessControlFlags {
            query[kSecAttrAccessControl as String] = try makeAccessControl(flag)
        } else {
            query[kSecAttrAccessible as String] = item.accessibility.secAttrValue
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // Upsert: refresh-token rotation needs overwrite semantics, not "add or fail".
            try update(data, for: item)
            return
        }
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
    }

    public func read(
        for item: KeychainItemDescriptor,
        context: LAContext? = nil
    ) throws(KeychainError) -> Data? {
        var query = searchQuery(for: item)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        // The biometric prompt string comes from `context.localizedReason`, the modern
        // replacement for the deprecated `kSecUseOperationPrompt`.
        if let context {
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // A missing item is a normal answer at this level, not an error —
        // matching the `SecItemCopyMatching` idiom.
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        return data
    }

    public func delete(for item: KeychainItemDescriptor) throws(KeychainError) {
        let status = SecItemDelete(searchQuery(for: item) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    private func update(_ data: Data, for item: KeychainItemDescriptor) throws(KeychainError) {
        let attributesToUpdate = [kSecValueData as String: data]
        let status = SecItemUpdate(searchQuery(for: item) as CFDictionary, attributesToUpdate as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
    }

    /// Search queries identify the item by class + service + account only.
    /// Accessibility/ACL attributes are set at save time; putting them in a search
    /// query would make lookups fail to match.
    private func searchQuery(for item: KeychainItemDescriptor) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: item.key,
        ]
    }

    private func makeAccessControl(_ flag: KeychainAccessControlFlag) throws(KeychainError) -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            flag.secFlag,
            &error
        ) else {
            throw KeychainError.accessControlCreationFailed
        }
        return accessControl
    }
}
