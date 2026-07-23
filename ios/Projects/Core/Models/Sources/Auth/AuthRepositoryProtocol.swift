// This protocol lives in Core/Models, not in a Feature's own domain layer, because both
// a Feature (as consumer) and Core/Networking (as implementer) depend on Core/Models — and
// the module rule is Features -> Core only, never Core -> Feature. Core/Models is the shared
// ground both sides already stand on, so the contract lives here. App wires the concrete
// Core/Networking implementation into each Feature's use case.

// Typed throws (SE-0413): the compiler guarantees that implementations can
// only fail with the domain error, so no transport error can leak to features.

public protocol AuthRepositoryProtocol: Sendable {
    func login(username: String, password: String) async throws(AuthError) -> TokenPair
    func refresh(refreshToken: String) async throws(AuthError) -> TokenPair
}
