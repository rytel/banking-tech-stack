import CoreModels
import CoreNetworking
import FeatureAuth
import FeatureTopicsList
import FeatureTopicDetail

/// The one place in the app allowed to know about concrete Core implementations.
/// Everything below only ever sees protocols.
@MainActor
enum CompositionRoot {
    static func makeAuthViewModel() -> AuthViewModel {
        let repository: AuthRepositoryProtocol = AuthRepository()
        return AuthViewModel(loginUseCase: LoginUseCase(repository: repository))
    }

    static func makeTopicsListViewModel() -> TopicsListViewModel {
        let repository: TopicsRepositoryProtocol = TopicsRepository()
        return TopicsListViewModel(fetchTopicsUseCase: FetchTopicsUseCase(repository: repository))
    }

    static func makeTopicDetailViewModel() -> TopicDetailViewModel {
        let repository: TopicsRepositoryProtocol = TopicsRepository()
        return TopicDetailViewModel(fetchTopicDetailUseCase: FetchTopicDetailUseCase(repository: repository))
    }
}
