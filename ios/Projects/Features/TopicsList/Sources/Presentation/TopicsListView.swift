import SwiftUI

public struct TopicsListView: View {
    @Bindable var viewModel: TopicsListViewModel
    var tickerViewModel: TickerViewModel
    var onSelectTopic: (String) -> Void

    public init(
        viewModel: TopicsListViewModel,
        tickerViewModel: TickerViewModel,
        onSelectTopic: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.tickerViewModel = tickerViewModel
        self.onSelectTopic = onSelectTopic
    }

    public var body: some View {
        VStack {
            if let serverTime = tickerViewModel.serverTime {
                Text(serverTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Topics")
                .accessibilityIdentifier("topicsTitle")

            TextField("Search topics", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
                .onChange(of: viewModel.query) {
                    viewModel.search()
                }

            if viewModel.isLoading {
                ProgressView()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            List(viewModel.topics, id: \.id) { topic in
                Button {
                    onSelectTopic(topic.id)
                } label: {
                    VStack(alignment: .leading) {
                        Text(topic.title)
                            .font(.headline)
                        Text(topic.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .task {
            tickerViewModel.start()
            viewModel.search()
        }
        .onDisappear { tickerViewModel.stop() }
    }
}

#if DEBUG
import Combine
import CoreModels

private struct PreviewFetchTopicsUseCase: FetchTopicsUseCaseProtocol {
    var result: Result<[Topic], TopicsError> = .success([
        Topic(id: "1", title: "JWT signing: ES256 vs HS256", description: "Why a client cannot verify an HS256 token without exposing the shared secret."),
        Topic(id: "2", title: "Refresh token single-flight", description: "Serializing concurrent token refreshes with an actor.")
    ])

    func execute(query: String?) async throws(TopicsError) -> [Topic] {
        switch result {
        case .success(let topics): return topics
        case .failure(let error): throw error
        }
    }
}

private struct PreviewTickerRepository: TickerRepositoryProtocol {
    func tickerUpdates() -> AnyPublisher<TickerUpdate, TickerError> {
        Just(TickerUpdate(serverTime: "2026-07-27T19:00:00Z"))
            .setFailureType(to: TickerError.self)
            .eraseToAnyPublisher()
    }
}

#Preview {
    TopicsListView(
        viewModel: TopicsListViewModel(fetchTopicsUseCase: PreviewFetchTopicsUseCase()),
        tickerViewModel: TickerViewModel(repository: PreviewTickerRepository()),
        onSelectTopic: { _ in }
    )
}
#endif
