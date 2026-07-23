import Testing
import CoreModels
@testable import FeatureTopicDetail

private struct StubFetchTopicDetailUseCase: FetchTopicDetailUseCaseProtocol {}

@MainActor
struct TopicDetailViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = TopicDetailViewModel(fetchTopicDetailUseCase: StubFetchTopicDetailUseCase())
        #expect(Bool(true))
    }
}
