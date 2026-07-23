import SwiftUI

public struct TopicsListView: View {
    var viewModel: TopicsListViewModel

    public init(viewModel: TopicsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Text("Topics")
    }
}
