import CoreModels
import Observation

@MainActor
@Observable
public final class TopicsListViewModel {
    public var query = ""
    public private(set) var topics: [Topic] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let fetchTopicsUseCase: FetchTopicsUseCaseProtocol
    private var searchTask: Task<Void, Never>?

    public init(fetchTopicsUseCase: FetchTopicsUseCaseProtocol) {
        self.fetchTopicsUseCase = fetchTopicsUseCase
    }

    /// Call this every time `query` changes. It cancels the previous
    /// in-flight search before starting a new one, so a slow, outdated
    /// response can never overwrite the result of a newer query.
    public func search() {
        searchTask?.cancel()

        let query = self.query
        searchTask = Task { [weak self] in
            do {
                // Debounce: if the user types again, the task above is
                // cancelled and this sleep throws before any request is sent.
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()

                guard let self else { return }
                self.isLoading = true
                defer { self.isLoading = false }

                let result = try await self.fetchTopicsUseCase.execute(query: query.isEmpty ? nil : query)
                try Task.checkCancellation()

                self.topics = result
                self.errorMessage = nil
            } catch is CancellationError {
                // Superseded by a newer search: nothing to show.
            } catch let error as TopicsError {
                self?.errorMessage = self?.message(for: error)
            } catch {
                self?.errorMessage = "Something went wrong. Try again."
            }
        }
    }

    private func message(for error: TopicsError) -> String? {
        switch error {
        case .offline: return "No internet connection."
        case .serverUnavailable: return "Server is unavailable. Try again later."
        case .unauthorized, .topicNotFound, .invalidData, .unknown: return "Something went wrong. Try again."
        case .cancelled: return nil
        }
    }
}
