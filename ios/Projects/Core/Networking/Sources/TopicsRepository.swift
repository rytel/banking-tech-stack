import Foundation
import CoreModels

public final class TopicsRepository: TopicsRepositoryProtocol {
    private let httpClient: HTTPClient

    public init(environment: APIEnvironment = .local) {
        self.httpClient = HTTPClient(environment: environment)
    }

    public func fetchTopics() async throws -> [Topic] {
        try await httpClient.execute(TopicsAPI.topics)
    }

    public func fetchTopic(id: String) async throws -> Topic {
        try await httpClient.execute(TopicsAPI.topic(id: id))
    }
}
