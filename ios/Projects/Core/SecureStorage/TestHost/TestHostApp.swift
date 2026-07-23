import SwiftUI

/// Minimal host app for the Keychain unit tests. It exists only so XCTest has a real app
/// process to inject into — one that carries a keychain access group. It renders nothing.
@main
struct TestHostApp: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}
