import Testing
import CoreModels
@testable import FeatureTopicDetail

private struct StubFetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol {
    var result: Result<TopicDetailResult, TopicsError> = .failure(.unknown)

    func execute(id: String) async throws(TopicsError) -> TopicDetailResult {
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}

@MainActor
struct TopicDetailViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = TopicDetailViewModel(fetchTopicDetailUseCase: StubFetchTopicDetailUseCase())
        #expect(Bool(true))
    }

    @Test func loadPopulatesTopicAndRelatedTopicsOnSuccess() async {
        let topic = Topic(id: "1", title: "JWT", description: "desc")
        let related = Topic(id: "2", title: "Pinning", description: "desc")
        let useCase = StubFetchTopicDetailUseCase(
            result: .success(TopicDetailResult(topic: topic, relatedTopics: [related]))
        )
        let viewModel = TopicDetailViewModel(fetchTopicDetailUseCase: useCase)

        await viewModel.load(id: "1")

        #expect(viewModel.topic == topic)
        #expect(viewModel.relatedTopics == [related])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadSetsErrorMessageOnFailure() async {
        let viewModel = TopicDetailViewModel(fetchTopicDetailUseCase: StubFetchTopicDetailUseCase(result: .failure(.topicNotFound)))

        await viewModel.load(id: "does-not-exist")

        #expect(viewModel.topic == nil)
        #expect(viewModel.errorMessage != nil)
    }
}
