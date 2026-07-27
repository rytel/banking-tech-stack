// Lives in Core/Models for the same reason as `TopicsRepositoryProtocol`: both a Feature
// (consumer) and Core/Networking (implementer) depend on Core/Models, and the module rule is
// Features -> Core only, never Core -> Feature.

public protocol SecretRepositoryProtocol: Sendable {
    func fetchSecret() async throws(SecretError) -> String
}
