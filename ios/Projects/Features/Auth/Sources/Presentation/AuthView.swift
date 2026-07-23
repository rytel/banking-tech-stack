import SwiftUI

public struct AuthView: View {
    var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Text("Auth")
    }
}
