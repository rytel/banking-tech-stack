import Foundation
import CoreModels

/// All auth API paths in one place, so they cannot be mistyped.
enum AuthPath: String {
    case login = "/auth/login"
    case refresh = "/auth/refresh"
}

/// Factories for the auth API calls.
enum AuthAPI {
    static func login(username: String, password: String) -> Request<TokenPair> {
        Request(
            path: AuthPath.login.rawValue,
            method: .post,
            body: LoginBody(username: username, password: password)
        )
    }

    static func refresh(token: String) -> Request<TokenPair> {
        Request(
            path: AuthPath.refresh.rawValue,
            method: .post,
            body: RefreshBody(refreshToken: token)
        )
    }

    private struct LoginBody: Encodable, Sendable {
        let username: String
        let password: String
    }

    private struct RefreshBody: Encodable, Sendable {
        let refreshToken: String
    }
}
