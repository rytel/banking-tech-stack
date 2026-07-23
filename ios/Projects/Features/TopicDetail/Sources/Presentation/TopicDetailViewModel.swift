import Observation

@MainActor
@Observable
public final class TopicDetailViewModel {
    private let fetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol

    public init(fetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol) {
        self.fetchTopicDetailUseCase = fetchTopicDetailUseCase
    }
}
