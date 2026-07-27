import Testing
import CoreModels
@testable import FeatureTopicsList

private struct StubFetchSecretUseCase: FetchSecretUseCaseProtocol {
    var result: Result<String, SecretError> = .failure(.unknown)

    func execute() async throws(SecretError) -> String {
        switch result {
        case .success(let secret): return secret
        case .failure(let error): throw error
        }
    }
}

@MainActor
struct SecretViewModelTests {
    @Test func viewModelCanBeBuiltWithAStubUseCase() {
        _ = SecretViewModel(
            fetchSecretUseCase: StubFetchSecretUseCase(),
            store: { _ in },
            unlock: { nil }
        )
        #expect(Bool(true))
    }

    @Test func revealPopulatesSecretOnSuccess() async {
        let box = SecretBox()
        let viewModel = SecretViewModel(
            fetchSecretUseCase: StubFetchSecretUseCase(result: .success("correct-horse-battery-staple")),
            store: { secret in await box.set(secret) },
            unlock: { await box.get() }
        )

        await viewModel.reveal()

        #expect(viewModel.revealedSecret == "correct-horse-battery-staple")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func revealSetsErrorMessageOnFetchFailure() async {
        let viewModel = SecretViewModel(
            fetchSecretUseCase: StubFetchSecretUseCase(result: .failure(.unauthorized)),
            store: { _ in },
            unlock: { "should not be reached" }
        )

        await viewModel.reveal()

        #expect(viewModel.revealedSecret == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func revealSetsErrorMessageWhenUnlockFails() async {
        let viewModel = SecretViewModel(
            fetchSecretUseCase: StubFetchSecretUseCase(result: .success("shh")),
            store: { _ in },
            unlock: { nil }
        )

        await viewModel.reveal()

        #expect(viewModel.revealedSecret == nil)
        #expect(viewModel.errorMessage != nil)
    }
}

private actor SecretBox {
    private var value: String?

    func set(_ newValue: String) {
        value = newValue
    }

    func get() -> String? {
        value
    }
}
