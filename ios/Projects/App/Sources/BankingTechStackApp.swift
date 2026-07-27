import SwiftUI

@main
struct BankingTechStackApp: App {
    init() {
        CompositionRoot.checkRASPStatusAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
