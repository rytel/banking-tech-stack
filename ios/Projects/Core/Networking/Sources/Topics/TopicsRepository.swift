import Foundation
import CoreModels

public final class TopicsRepository: TopicsRepositoryProtocol {
    private let httpClient: HTTPClient

    public init(environment: APIEnvironment = .local, urlSession: URLSession = .shared) {
        self.httpClient = HTTPClient(environment: environment, urlSession: urlSession)
    }

    public func fetchTopics(query: String? = nil) async throws(TopicsError) -> [Topic] {
        do {
            return try await httpClient.execute(TopicsAPI.topics(query: query))
        } catch {
            // Typed throws on `execute` makes `error` a `NetworkError` here.
            throw TopicsError(error)
        }
    }

    public func fetchTopic(id: String) async throws(TopicsError) -> Topic {
        do {
            return try await httpClient.execute(TopicsAPI.topic(id: id))
        } catch {
            throw TopicsError(error)
        }
    }
}
