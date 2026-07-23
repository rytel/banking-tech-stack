import Testing
@testable import App

struct CompositionRootTests {
    @Test func compositionRootBuildsAuthViewModel() {
        _ = CompositionRoot.makeAuthViewModel()
        #expect(Bool(true))
    }

    @Test func compositionRootBuildsTopicsListViewModel() {
        _ = CompositionRoot.makeTopicsListViewModel()
        #expect(Bool(true))
    }

    @Test func compositionRootBuildsTopicDetailViewModel() {
        _ = CompositionRoot.makeTopicDetailViewModel()
        #expect(Bool(true))
    }
}
