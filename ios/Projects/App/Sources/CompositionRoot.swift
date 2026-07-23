import CoreModels
import CoreNetworking
import CoreSecureStorage
import FeatureAuth
import FeatureTopicsList
import FeatureTopicDetail

/// The one place in the app allowed to know about concrete Core implementations.
/// Everything below only ever sees protocols.
@MainActor
enum CompositionRoot {
    /// A `static let` so the in-memory access token survives the app's lifetime instead of
    /// being recreated (and lost) on every `makeAuthViewModel()` call.
    private static let authSessionStore: AuthSessionStoring = AuthSessionStore()

    static func makeAuthViewModel() -> AuthViewModel {
        let repository: AuthRepositoryProtocol = AuthRepository()
        return AuthViewModel(
            loginUseCase: LoginUseCase(repository: repository),
            onLoginSuccess: { tokens in
                try? await CompositionRoot.authSessionStore.save(tokens)
            }
        )
    }

    static func makeTopicsListViewModel() -> TopicsListViewModel {
        let repository: TopicsRepositoryProtocol = TopicsRepository()
        return TopicsListViewModel(fetchTopicsUseCase: FetchTopicsUseCase(repository: repository))
    }

    static func makeTickerViewModel() -> TickerViewModel {
        let repository: TickerRepositoryProtocol = TickerRepository()
        return TickerViewModel(repository: repository)
    }

    static func makeTopicDetailViewModel() -> TopicDetailViewModel {
        let repository: TopicsRepositoryProtocol = TopicsRepository()
        return TopicDetailViewModel(fetchTopicDetailUseCase: FetchTopicDetailUseCase(repository: repository))
    }
}
