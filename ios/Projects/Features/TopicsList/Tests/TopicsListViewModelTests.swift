import Testing
import CoreModels
@testable import FeatureTopicsList

private struct StubFetchTopicsUseCase: FetchTopicsUseCaseProtocol {
    var result: Result<[Topic], TopicsError> = .success([])

    func execute(query: String?) async throws(TopicsError) -> [Topic] {
        switch result {
        case .success(let topics): return topics
        case .failure(let error): throw error
        }
    }
}

@MainActor
struct TopicsListViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = TopicsListViewModel(fetchTopicsUseCase: StubFetchTopicsUseCase())
        #expect(Bool(true))
    }

    @Test func searchPopulatesTopicsOnSuccess() async throws {
        let topics = [Topic(id: "1", title: "JWT", description: "desc")]
        let viewModel = TopicsListViewModel(fetchTopicsUseCase: StubFetchTopicsUseCase(result: .success(topics)))

        viewModel.query = "jwt"
        viewModel.search()
        try await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.topics == topics)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func searchSetsErrorMessageOnFailure() async throws {
        let viewModel = TopicsListViewModel(fetchTopicsUseCase: StubFetchTopicsUseCase(result: .failure(.offline)))

        viewModel.search()
        try await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.errorMessage != nil)
    }
}
