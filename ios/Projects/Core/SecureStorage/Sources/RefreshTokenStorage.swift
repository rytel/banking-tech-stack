import Foundation

public protocol RefreshTokenStorageProtocol: Sendable {
    func save(_ token: String) throws(KeychainError)
    func read() throws(KeychainError) -> String?
    func delete() throws(KeychainError)
}

public final class KeychainRefreshTokenStorage: RefreshTokenStorageProtocol {
    private let storage: SecureStorageProtocol
    private let item: KeychainItemDescriptor

    public init(storage: SecureStorageProtocol = KeychainSecureStorage(), key: String = "auth.refreshToken") {
        self.storage = storage
        // `ThisDeviceOnly` excludes the item from encrypted iCloud/iTunes backups entirely.
        // A plain `WhenUnlocked` item would be restored onto a new physical device, silently
        // handing that device the user's session; `ThisDeviceOnly` forces re-login after a
        // device restore instead.
        self.item = KeychainItemDescriptor(key: key, accessibility: .whenUnlockedThisDeviceOnly)
    }

    public func save(_ token: String) throws(KeychainError) {
        try storage.save(Data(token.utf8), for: item)
    }

    public func read() throws(KeychainError) -> String? {
        guard let data = try storage.read(for: item) else {
            return nil
        }
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return token
    }

    public func delete() throws(KeychainError) {
        try storage.delete(for: item)
    }
}
