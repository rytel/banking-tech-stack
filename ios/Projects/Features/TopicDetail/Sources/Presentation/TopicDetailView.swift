import SwiftUI

public struct TopicDetailView: View {
    var viewModel: TopicDetailViewModel

    public init(viewModel: TopicDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Text("Topic detail")
    }
}
