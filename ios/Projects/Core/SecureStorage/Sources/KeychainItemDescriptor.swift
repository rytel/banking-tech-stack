public struct KeychainItemDescriptor: Sendable {
    public let key: String
    public let accessibility: KeychainAccessibility
    public let accessControlFlags: KeychainAccessControlFlag?

    /// `kSecAttrAccessible` and `kSecAttrAccessControl` are mutually exclusive in a
    /// Keychain query — when `accessControlFlags` is set, `KeychainSecureStorage` builds
    /// the ACL via `SecAccessControlCreateWithFlags` and omits the plain accessibility
    /// attribute (the ACL already encodes an accessibility internally).
    public init(
        key: String,
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly,
        accessControlFlags: KeychainAccessControlFlag? = nil
    ) {
        self.key = key
        self.accessibility = accessibility
        self.accessControlFlags = accessControlFlags
    }
}
