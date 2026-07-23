import CoreModels

/// Composes the two persisted token policies — refresh token in the Keychain, access token
/// in memory — so the composition root has a single call to make after login.
public protocol AuthSessionStoring: Sendable {
    func save(_ tokens: TokenPair) async throws(KeychainError)
    func accessToken() async -> String?
    func clearSession() async throws(KeychainError)
}

public final class AuthSessionStore: AuthSessionStoring {
    private let refreshTokenStorage: RefreshTokenStorageProtocol
    private let accessTokenStore: AccessTokenStoring

    public init(
        refreshTokenStorage: RefreshTokenStorageProtocol = KeychainRefreshTokenStorage(),
        accessTokenStore: AccessTokenStoring = AccessTokenStore()
    ) {
        self.refreshTokenStorage = refreshTokenStorage
        self.accessTokenStore = accessTokenStore
    }

    public func save(_ tokens: TokenPair) async throws(KeychainError) {
        try refreshTokenStorage.save(tokens.refreshToken)
        await accessTokenStore.set(tokens.accessToken)
    }

    public func accessToken() async -> String? {
        await accessTokenStore.currentToken()
    }

    public func clearSession() async throws(KeychainError) {
        try refreshTokenStorage.delete()
        await accessTokenStore.set(nil)
    }
}
