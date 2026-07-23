import Foundation

/// The backend environments the app can talk to.
/// Base URLs live only here, so no other code repeats them.
public enum APIEnvironment: Sendable {
    case local
    case production

    var baseURL: URL {
        switch self {
        case .local: URL(string: "https://localhost:8443")!
        case .production: URL(string: "https://api.example.com")!
        }
    }

    var webSocketBaseURL: URL {
        switch self {
        case .local: URL(string: "wss://localhost:8443")!
        case .production: URL(string: "wss://api.example.com")!
        }
    }
}
