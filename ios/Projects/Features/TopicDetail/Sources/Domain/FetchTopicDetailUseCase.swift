import CoreModels

public protocol FetchTopicDetailUseCaseProtocol {
    // Day 3: func execute(id: String) async throws -> Topic
}

public final class FetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol {
    private let repository: TopicsRepositoryProtocol

    public init(repository: TopicsRepositoryProtocol) {
        self.repository = repository
    }
}
