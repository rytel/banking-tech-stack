import Combine

public final class TopicsListViewModel: ObservableObject {
    private let fetchTopicsUseCase: FetchTopicsUseCaseProtocol

    public init(fetchTopicsUseCase: FetchTopicsUseCaseProtocol) {
        self.fetchTopicsUseCase = fetchTopicsUseCase
    }
}
