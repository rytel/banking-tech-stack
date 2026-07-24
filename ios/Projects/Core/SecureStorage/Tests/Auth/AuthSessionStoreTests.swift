import XCTest
import Foundation
import CoreModels
@testable import CoreSecureStorage

final class AuthSessionStoreTests: XCTestCase {
    func test_save_persistsRefreshToken_andHoldsAccessToken() async throws {
        let refresh = FakeRefreshTokenStorage()
        let access = SpyAccessTokenStore()
        let store = AuthSessionStore(refreshTokenStorage: refresh, accessTokenStore: access)

        try await store.save(TokenPair(accessToken: "access-1", refreshToken: "refresh-1", expiresIn: 900))

        XCTAssertEqual(refresh.savedToken, "refresh-1")
        let held = await access.currentToken()
        XCTAssertEqual(held, "access-1")
    }

    func test_clearSession_clearsBothStores() async throws {
        let refresh = FakeRefreshTokenStorage()
        let access = SpyAccessTokenStore()
        let store = AuthSessionStore(refreshTokenStorage: refresh, accessTokenStore: access)
        try await store.save(TokenPair(accessToken: "access-1", refreshToken: "refresh-1", expiresIn: 900))

        try await store.clearSession()

        XCTAssertTrue(refresh.didDelete)
        let held = await access.currentToken()
        XCTAssertNil(held)
    }
}

private final class FakeRefreshTokenStorage: RefreshTokenStorageProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _savedToken: String?
    private var _didDelete = false

    var savedToken: String? {
        lock.withLock { _savedToken }
    }
    var didDelete: Bool {
        lock.withLock { _didDelete }
    }

    func save(_ token: String) throws(KeychainError) {
        lock.withLock { _savedToken = token }
    }

    func read() throws(KeychainError) -> String? {
        lock.withLock { _savedToken }
    }

    func delete() throws(KeychainError) {
        lock.withLock {
            _savedToken = nil
            _didDelete = true
        }
    }
}

private actor SpyAccessTokenStore: AccessTokenStoring {
    private var token: String?

    func set(_ token: String?) {
        self.token = token
    }

    func currentToken() -> String? {
        token
    }
}
