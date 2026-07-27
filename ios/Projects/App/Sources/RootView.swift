import FeatureAuth
import SwiftUI

/// Switches between the login screen and the authenticated area, based on
/// `AuthViewModel.isAuthenticated`. Kept as its own `@State` so the view
/// model survives across body re-evaluations instead of being recreated.
struct RootView: View {
    @State private var authViewModel = CompositionRoot.makeAuthViewModel()

    var body: some View {
        if authViewModel.isAuthenticated {
            TopicsCoordinatorView(authViewModel: authViewModel)
        } else {
            AuthView(viewModel: authViewModel)
        }
    }
}
