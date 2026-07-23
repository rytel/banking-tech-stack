import XCTest
import Foundation
import CoreModels
@testable import CoreSecureStorage

final class TokenRefreshCoordinatorTests: XCTestCase {
    private let rotated = TokenPair(accessToken: "new-access", refreshToken: "new-refresh", expiresIn: 900)

    // The core single-flight guarantee: N concurrent callers must trigger exactly one refresh.
    func test_concurrentRefresh_triggersSingleNetworkCall() async throws {
        let repository = SpyAuthRepository(result: rotated)
        let session = FakeAuthSessionStore(refreshToken: "stored-refresh")
        let coordinator = TokenRefreshCoordinator(authRepository: repository, sessionStore: session)
        await repository.closeGate()

        let arrivals = Counter()
        let count = 100

        let results = try await withThrowingTaskGroup(of: TokenPair.self) { group -> [TokenPair] in
            for _ in 0..<count {
                group.addTask {
                    await arrivals.increment()
                    return try await coordinator.refresh()
                }
            }
            // Let every caller reach the coordinator and the single leader begin its refresh,
            // so the other callers pile up as joiners behind the closed gate.
            await arrivals.waitUntil(count)
            await repository.waitUntilRefreshStarted()
            for _ in 0..<10 { await Task.yield() }
            await repository.openGate()

            var collected: [TokenPair] = []
            for try await pair in group { collected.append(pair) }
            return collected
        }

        let calls = await repository.refreshCallCount
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(results.count, count)
        XCTAssertTrue(results.allSatisfy { $0 == rotated })
    }

    // After a refresh completes, the coordinator must reset so the next batch refreshes again.
    func test_refresh_resetsAfterSuccess() async throws {
        let repository = SpyAuthRepository(result: rotated)
        let session = FakeAuthSessionStore(refreshToken: "stored-refresh")
        let coordinator = TokenRefreshCoordinator(authRepository: repository, sessionStore: session)

        _ = try await coordinator.refresh()
        _ = try await coordinator.refresh()

        let calls = await repository.refreshCallCount
        XCTAssertEqual(calls, 2)
    }

    // A failing refresh must fan the same error out to every joined caller and still reset.
    func test_concurrentRefresh_failure_fansOutErrorAndResets() async throws {
        let repository = SpyAuthRepository(result: rotated, error: .sessionExpired)
        let session = FakeAuthSessionStore(refreshToken: "stored-refresh")
        let coordinator = TokenRefreshCoordinator(authRepository: repository, sessionStore: session)
        await repository.closeGate()

        let arrivals = Counter()
        let count = 10

        let errors = await withTaskGroup(of: AuthError?.self) { group -> [AuthError?] in
            for _ in 0..<count {
                group.addTask {
                    await arrivals.increment()
                    do {
                        _ = try await coordinator.refresh()
                        return nil
                    } catch let error as AuthError {
                        return error
                    } catch {
                        return nil
                    }
                }
            }
            await arrivals.waitUntil(count)
            await repository.waitUntilRefreshStarted()
            for _ in 0..<10 { await Task.yield() }
            await repository.openGate()

            var collected: [AuthError?] = []
            for await error in group { collected.append(error) }
            return collected
        }

        let calls = await repository.refreshCallCount
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(errors.count, count)
        XCTAssertTrue(errors.allSatisfy { $0 == .sessionExpired })

        // Reset holds on the error path too: a fresh call starts a new refresh.
        do {
            _ = try await coordinator.refresh()
            XCTFail("Expected sessionExpired")
        } catch {
            XCTAssertEqual(error, .sessionExpired)
        }
        let callsAfter = await repository.refreshCallCount
        XCTAssertEqual(callsAfter, 2)
    }

    // The rotated pair returned by the backend must be persisted.
    func test_refresh_persistsRotatedTokens() async throws {
        let repository = SpyAuthRepository(result: rotated)
        let session = FakeAuthSessionStore(refreshToken: "stored-refresh")
        let coordinator = TokenRefreshCoordinator(authRepository: repository, sessionStore: session)

        _ = try await coordinator.refresh()

        let saved = await session.savedTokens
        XCTAssertEqual(saved, rotated)
    }

    // With no stored refresh token there is nothing to refresh with — fail without a network call.
    func test_refresh_withoutStoredToken_failsAndSkipsNetwork() async throws {
        let repository = SpyAuthRepository(result: rotated)
        let session = FakeAuthSessionStore(refreshToken: nil)
        let coordinator = TokenRefreshCoordinator(authRepository: repository, sessionStore: session)

        do {
            _ = try await coordinator.refresh()
            XCTFail("Expected sessionExpired")
        } catch {
            XCTAssertEqual(error, .sessionExpired)
        }

        let calls = await repository.refreshCallCount
        XCTAssertEqual(calls, 0)
    }
}

// MARK: - Test doubles

private actor SpyAuthRepository: AuthRepositoryProtocol {
    private(set) var refreshCallCount = 0
    private let result: TokenPair
    private let error: AuthError?

    private var isGateOpen = true
    private var gateWaiters: [CheckedContinuation<Void, Never>] = []
    private var startedWaiters: [CheckedContinuation<Void, Never>] = []

    init(result: TokenPair, error: AuthError? = nil) {
        self.result = result
        self.error = error
    }

    func closeGate() {
        isGateOpen = false
    }

    func openGate() {
        isGateOpen = true
        let waiters = gateWaiters
        gateWaiters.removeAll()
        for waiter in waiters { waiter.resume() }
    }

    func waitUntilRefreshStarted() async {
        if refreshCallCount > 0 { return }
        await withCheckedContinuation { continuation in
            startedWaiters.append(continuation)
        }
    }

    func login(username: String, password: String) throws(AuthError) -> TokenPair {
        throw AuthError.unknown
    }

    func refresh(refreshToken: String) async throws(AuthError) -> TokenPair {
        refreshCallCount += 1
        let started = startedWaiters
        startedWaiters.removeAll()
        for waiter in started { waiter.resume() }

        if !isGateOpen {
            await withCheckedContinuation { continuation in
                gateWaiters.append(continuation)
            }
        }

        if let error { throw error }
        return result
    }
}

private actor FakeAuthSessionStore: AuthSessionStoring {
    private var storedRefreshToken: String?
    private var accessTokenValue: String?
    private(set) var savedTokens: TokenPair?

    init(refreshToken: String?) {
        self.storedRefreshToken = refreshToken
    }

    func save(_ tokens: TokenPair) throws(KeychainError) {
        savedTokens = tokens
        storedRefreshToken = tokens.refreshToken
        accessTokenValue = tokens.accessToken
    }

    func accessToken() -> String? {
        accessTokenValue
    }

    func refreshToken() throws(KeychainError) -> String? {
        storedRefreshToken
    }

    func clearSession() throws(KeychainError) {
        storedRefreshToken = nil
        accessTokenValue = nil
    }
}

/// Counts arrivals so a test can wait until all concurrent callers have started before releasing them.
private actor Counter {
    private var value = 0
    private var waiters: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func increment() {
        value += 1
        waiters.removeAll { waiter in
            if value >= waiter.target {
                waiter.continuation.resume()
                return true
            }
            return false
        }
    }

    func waitUntil(_ target: Int) async {
        if value >= target { return }
        await withCheckedContinuation { continuation in
            waiters.append((target, continuation))
        }
    }
}
