import Observation

@MainActor
@Observable
public final class TopicsListViewModel {
    private let fetchTopicsUseCase: FetchTopicsUseCaseProtocol

    public init(fetchTopicsUseCase: FetchTopicsUseCaseProtocol) {
        self.fetchTopicsUseCase = fetchTopicsUseCase
    }
}
