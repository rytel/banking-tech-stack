// These protocols live in Core/Models, not in a Feature's own domain layer, because both
// a Feature (as consumer) and Core/Networking (as implementer) depend on Core/Models — and
// the module rule is Features -> Core only, never Core -> Feature. Core/Models is the shared
// ground both sides already stand on, so the contract lives here. App wires the concrete
// Core/Networking implementation into each Feature's use case.

public protocol AuthRepositoryProtocol: Sendable {
    func login(username: String, password: String) async throws -> TokenPair
    func refresh(refreshToken: String) async throws -> TokenPair
}

public protocol TopicsRepositoryProtocol: Sendable {
    func fetchTopics() async throws -> [Topic]
    func fetchTopic(id: String) async throws -> Topic
}
