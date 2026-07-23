public protocol SecureStorageProtocol {
    // Day 4: func save(_ data: Data, for key: String) throws
    // Day 4: func read(for key: String) throws -> Data?
}

// Day 4 fills this in with a thin wrapper over the Security framework (raw Keychain API).
public final class KeychainSecureStorage: SecureStorageProtocol {
    public init() {}
}
