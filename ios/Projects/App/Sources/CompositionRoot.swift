import CoreModels
import Foundation
import CoreNetworking
import CoreRASP
import CoreSecureStorage
import FeatureAuth
import FeatureTopicsList
import FeatureTopicDetail
import os

/// The one place in the app allowed to know about concrete Core implementations.
/// Everything below only ever sees protocols.
@MainActor
enum CompositionRoot {
    private static let environment: APIEnvironment = .local

    /// Logs the RASP status at launch. This is a signal to watch, not a
    /// security gate: both checks are bypassable on a compromised device
    /// (see `CoreRASP.DebuggerCheck` / `JailbreakCheck`), so the app never
    /// blocks login or any flow on the result — it only gets logged.
    private static let raspStatus: RASPStatus = {
        let status = RASPCheck.currentStatus()
        if status.isDebuggerAttached || status.isLikelyJailbroken {
            Logger(subsystem: "dev.rflrytel.bankingtechstack", category: "RASP")
                .warning("RASP signal detected: debuggerAttached=\(status.isDebuggerAttached), likelyJailbroken=\(status.isLikelyJailbroken)")
        }
        return status
    }()

    /// Forces the lazily-initialized `raspStatus` to run. Call once at app
    /// launch (`BankingTechStackApp.init`) — a `static let` only evaluates on
    /// first access, so without this call the check would never run.
    static func checkRASPStatusAtLaunch() {
        _ = raspStatus
    }

    /// One SPKI-pinned session shared by every repository, so all HTTP and
    /// WebSocket traffic goes through the same pinning delegate (and reuses
    /// the same connections).
    private static let pinnedSession: URLSession = .pinned(for: environment)

    /// A `static let` so the in-memory access token survives the app's lifetime instead of
    /// being recreated (and lost) on every `makeAuthViewModel()` call.
    private static let authSessionStore: AuthSessionStoring = AuthSessionStore()

    /// Serializes token refresh so N concurrent 401s trigger a single refresh (single-flight).
    /// Wired and ready, but not yet consumed: the request path (`Authorization`-header injection
    /// and a 401 -> refresh -> retry interceptor in the HTTP client) is a deliberate follow-up.
    static let tokenRefreshCoordinator: TokenRefreshing = TokenRefreshCoordinator(
        authRepository: AuthRepository(environment: environment, urlSession: pinnedSession),
        sessionStore: authSessionStore
    )

    static func makeAuthViewModel() -> AuthViewModel {
        let repository: AuthRepositoryProtocol = AuthRepository(environment: environment, urlSession: pinnedSession)
        return AuthViewModel(
            loginUseCase: LoginUseCase(repository: repository),
            onLoginSuccess: { tokens in
                try? await CompositionRoot.authSessionStore.save(tokens)
            }
        )
    }

    static func makeTopicsListViewModel() -> TopicsListViewModel {
        let repository: TopicsRepositoryProtocol = TopicsRepository(environment: environment, urlSession: pinnedSession)
        return TopicsListViewModel(fetchTopicsUseCase: FetchTopicsUseCase(repository: repository))
    }

    static func makeTickerViewModel() -> TickerViewModel {
        let repository: TickerRepositoryProtocol = TickerRepository(environment: environment, urlSession: pinnedSession)
        return TickerViewModel(repository: repository)
    }

    static func makeTopicDetailViewModel() -> TopicDetailViewModel {
        let repository: TopicsRepositoryProtocol = TopicsRepository(environment: environment, urlSession: pinnedSession)
        return TopicDetailViewModel(fetchTopicDetailUseCase: FetchTopicDetailUseCase(repository: repository))
    }
}
