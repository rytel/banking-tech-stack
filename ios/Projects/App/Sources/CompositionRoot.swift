import CoreModels
import Foundation
import CoreNetworking
import CoreSecureStorage
import FeatureAuth
import FeatureTopicsList
import FeatureTopicDetail

/// The one place in the app allowed to know about concrete Core implementations.
/// Everything below only ever sees protocols.
@MainActor
enum CompositionRoot {
    private static let environment: APIEnvironment = .local

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
