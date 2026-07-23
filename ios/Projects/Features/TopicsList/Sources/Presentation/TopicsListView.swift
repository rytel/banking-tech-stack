import SwiftUI

public struct TopicsListView: View {
    var viewModel: TopicsListViewModel
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
        }
        .task { tickerViewModel.start() }
        .onDisappear { tickerViewModel.stop() }
    }
}
