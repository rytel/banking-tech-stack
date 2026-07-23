import Testing
import CoreModels
@testable import FeatureAuth

private struct StubLoginUseCase: LoginUseCaseProtocol {}

struct AuthViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = AuthViewModel(loginUseCase: StubLoginUseCase())
        #expect(Bool(true))
    }
}
