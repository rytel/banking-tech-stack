import CoreModels

public protocol FetchTopicsUseCaseProtocol: Sendable {
    func execute(query: String?) async throws(TopicsError) -> [Topic]
}

public final class FetchTopicsUseCase: FetchTopicsUseCaseProtocol {
    private let repository: TopicsRepositoryProtocol

    public init(repository: TopicsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String?) async throws(TopicsError) -> [Topic] {
        try await repository.fetchTopics(query: query)
    }
}
