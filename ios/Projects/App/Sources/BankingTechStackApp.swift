import SwiftUI
import FeatureAuth

@main
struct BankingTechStackApp: App {
    init() {
        CompositionRoot.checkRASPStatusAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
            AuthView(viewModel: CompositionRoot.makeAuthViewModel())
        }
    }
}
