import CoreModels

public protocol FetchTopicsUseCaseProtocol {
    // Day 3: func execute() async throws -> [Topic]
}

public final class FetchTopicsUseCase: FetchTopicsUseCaseProtocol {
    private let repository: TopicsRepositoryProtocol

    public init(repository: TopicsRepositoryProtocol) {
        self.repository = repository
    }
}
