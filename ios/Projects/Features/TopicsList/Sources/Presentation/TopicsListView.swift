import SwiftUI

public struct TopicsListView: View {
    @Bindable var viewModel: TopicsListViewModel
    var tickerViewModel: TickerViewModel

    public init(viewModel: TopicsListViewModel, tickerViewModel: TickerViewModel) {
        self.viewModel = viewModel
        self.tickerViewModel = tickerViewModel
    }

    public var body: some View {
        VStack {
            if let serverTime = tickerViewModel.serverTime {
                Text(serverTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Topics")

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
                VStack(alignment: .leading) {
                    Text(topic.title)
                        .font(.headline)
                    Text(topic.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
