import CoreModels
import Observation

@MainActor
@Observable
public final class TopicDetailViewModel {
    public private(set) var topic: Topic?
    public private(set) var relatedTopics: [Topic] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let fetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol

    public init(fetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol) {
        self.fetchTopicDetailUseCase = fetchTopicDetailUseCase
    }

    public func load(id: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await fetchTopicDetailUseCase.execute(id: id)
            topic = result.topic
            relatedTopics = result.relatedTopics
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: TopicsError) -> String? {
        switch error {
        case .offline: return "No internet connection."
        case .topicNotFound: return "Topic not found."
        case .serverUnavailable: return "Server is unavailable. Try again later."
        case .unauthorized, .invalidData, .unknown: return "Something went wrong. Try again."
        case .cancelled: return nil
        }
    }
}
