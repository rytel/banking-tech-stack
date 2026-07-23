import CoreModels

/// Serializes token refresh so that N concurrent callers trigger exactly one network refresh.
///
/// When an access token expires, several in-flight requests can each receive a 401 at the same
/// moment. Firing one refresh per 401 is wasteful and, with a single-use refresh token that the
/// backend rotates on every call, actively harmful: the parallel refreshes race to invalidate and
/// overwrite each other's tokens. This "single-flight" actor lets the first caller start the
/// refresh and every caller that arrives while it is in flight join the same result.
public protocol TokenRefreshing: Sendable {
    func refresh() async throws(AuthError) -> TokenPair
}

public actor TokenRefreshCoordinator: TokenRefreshing {
    private let authRepository: AuthRepositoryProtocol
    private let sessionStore: AuthSessionStoring

    /// The one refresh currently in flight, or `nil` when idle. `Task` carries an untyped `Error`
    /// because it cannot express typed throws; callers get the typed `AuthError` back via `result(of:)`.
    private var inFlight: Task<TokenPair, Error>?

    public init(authRepository: AuthRepositoryProtocol, sessionStore: AuthSessionStoring) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
    }

    public func refresh() async throws(AuthError) -> TokenPair {
        // Joiner: a refresh is already running — await the same task and mutate no state.
        if let task = inFlight {
            return try await Self.result(of: task)
        }

        // Leader: start the single refresh. There is no `await` between reading `inFlight` above
        // and assigning it below, so on the actor this check-and-set is atomic: any caller that
        // enters while the leader is suspended sees a non-nil `inFlight` and joins it.
        let task = Task { [authRepository, sessionStore] () throws -> TokenPair in
            guard let refreshToken = try await sessionStore.refreshToken() else {
                throw AuthError.sessionExpired
            }
            let pair = try await authRepository.refresh(refreshToken: refreshToken)
            try await sessionStore.save(pair) // persist the rotated pair
            return pair
        }
        inFlight = task

        // Only the leader reaches this line (joiners returned above), and it clears `inFlight`
        // synchronously on return — there is no `await` between the awaited result and this
        // `defer`, so no other call can interleave and a new leader can only start once we are done.
        defer { inFlight = nil }
        return try await Self.result(of: task)
    }

    /// Bridges the task's untyped `Error` back to the public `AuthError`, keeping the SE-0413
    /// typed-throws contract.
    private static func result(of task: Task<TokenPair, Error>) async throws(AuthError) -> TokenPair {
        do {
            return try await task.value
        } catch let error as AuthError {
            throw error
        } catch is CancellationError {
            throw AuthError.cancelled
        } catch {
            throw AuthError.unknown
        }
    }
}
