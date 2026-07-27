import FeatureAuth
import FeatureTopicDetail
import FeatureTopicsList
import SwiftUI

/// Composes the authenticated area: topic list, topic detail navigation,
/// and the protected-secret sheet, all wired through `CompositionRoot`.
struct TopicsCoordinatorView: View {
    var authViewModel: AuthViewModel

    @State private var path: [String] = []
    @State private var topicsListViewModel = CompositionRoot.makeTopicsListViewModel()
    @State private var tickerViewModel = CompositionRoot.makeTickerViewModel()
    @State private var isShowingSecret = false

    var body: some View {
        NavigationStack(path: $path) {
            TopicsListView(
                viewModel: topicsListViewModel,
                tickerViewModel: tickerViewModel,
                onSelectTopic: { topicId in path.append(topicId) }
            )
            .navigationTitle("Topics")
            .navigationDestination(for: String.self) { topicId in
                TopicDetailView(viewModel: CompositionRoot.makeTopicDetailViewModel(), topicId: topicId)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Log out") {
                        Task { await authViewModel.logout() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSecret = true
                    } label: {
                        Image(systemName: "lock.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingSecret) {
                SecretView(viewModel: CompositionRoot.makeSecretViewModel())
            }
        }
    }
}
