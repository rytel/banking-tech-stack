import Combine

public final class TopicDetailViewModel: ObservableObject {
    private let fetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol

    public init(fetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol) {
        self.fetchTopicDetailUseCase = fetchTopicDetailUseCase
    }
}
