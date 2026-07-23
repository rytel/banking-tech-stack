import SwiftUI
import FeatureAuth

@main
struct BankingTechStackApp: App {
    var body: some Scene {
        WindowGroup {
            AuthView(viewModel: CompositionRoot.makeAuthViewModel())
        }
    }
}
