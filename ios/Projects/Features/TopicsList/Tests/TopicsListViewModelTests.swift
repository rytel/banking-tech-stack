import Testing
import CoreModels
@testable import FeatureTopicsList

private struct StubFetchTopicsUseCase: FetchTopicsUseCaseProtocol {}

@MainActor
struct TopicsListViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = TopicsListViewModel(fetchTopicsUseCase: StubFetchTopicsUseCase())
        #expect(Bool(true))
    }
}
