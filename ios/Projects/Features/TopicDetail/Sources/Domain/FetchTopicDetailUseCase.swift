import CoreModels

public struct TopicDetailResult: Sendable, Equatable {
    public let topic: Topic
    public let relatedTopics: [Topic]

    public init(topic: Topic, relatedTopics: [Topic]) {
        self.topic = topic
        self.relatedTopics = relatedTopics
    }
}

public protocol FetchTopicDetailUseCaseProtocol: Sendable {
    func execute(id: String) async throws(TopicsError) -> TopicDetailResult
}

public final class FetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol {
    private enum FetchedResource {
        case topic(Topic)
        case allTopics([Topic])
    }

    private let repository: TopicsRepositoryProtocol

    public init(repository: TopicsRepositoryProtocol) {
        self.repository = repository
    }

    /// Fetches the topic and the full topics list (used to derive "related
    /// topics") in parallel, since the two calls are independent of each other.
    public func execute(id: String) async throws(TopicsError) -> TopicDetailResult {
        let repository = self.repository

        do {
            var topic: Topic?
            var allTopics: [Topic] = []

            // `withThrowingTaskGroup` only accepts untyped `throws`, so the
            // group itself is untyped and we map back to `TopicsError` below.
            try await withThrowingTaskGroup(of: FetchedResource.self) { group in
                group.addTask { .topic(try await repository.fetchTopic(id: id)) }
                group.addTask { .allTopics(try await repository.fetchTopics()) }

                for try await resource in group {
                    switch resource {
                    case .topic(let value): topic = value
                    case .allTopics(let value): allTopics = value
                    }
                }
            }

            guard let topic else {
                throw TopicsError.unknown
            }
            return TopicDetailResult(
                topic: topic,
                relatedTopics: allTopics.filter { $0.id != topic.id }
            )
        } catch let error as TopicsError {
            throw error
        } catch {
            throw TopicsError.unknown
        }
    }
}
