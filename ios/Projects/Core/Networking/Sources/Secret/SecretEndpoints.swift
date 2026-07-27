import Foundation
import CoreModels

struct SecretResponse: Decodable, Sendable {
    let secret: String
}

/// Factory for the `/secret` API call.
enum SecretAPI {
    static func secret() -> Request<SecretResponse> {
        Request(path: "/secret", method: .get, requiresAuth: true)
    }
}
