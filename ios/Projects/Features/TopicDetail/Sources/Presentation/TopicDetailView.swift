import SwiftUI

public struct TopicDetailView: View {
    var viewModel: TopicDetailViewModel
    let topicId: String

    public init(viewModel: TopicDetailViewModel, topicId: String) {
        self.viewModel = viewModel
        self.topicId = topicId
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let topic = viewModel.topic {
                    Text(topic.title)
                        .font(.largeTitle.bold())
                    Text(topic.description)
                        .font(.body)
                }

                if !viewModel.relatedTopics.isEmpty {
                    Text("Related topics")
                        .font(.headline)
                        .padding(.top)

                    ForEach(viewModel.relatedTopics, id: \.id) { related in
                        VStack(alignment: .leading) {
                            Text(related.title)
                                .font(.subheadline.bold())
                            Text(related.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .task { await viewModel.load(id: topicId) }
    }
}
