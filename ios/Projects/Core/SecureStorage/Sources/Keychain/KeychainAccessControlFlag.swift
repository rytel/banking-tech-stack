import Security

/// Deliberately curated, not a pass-through of `SecAccessControlCreateFlags` — only
/// exposes what this app needs.
public enum KeychainAccessControlFlag: Sendable {
    /// Unlike `.biometryAny`, `.biometryCurrentSet` invalidates the ACL if the enrolled
    /// Face ID / Touch ID set changes, forcing re-authentication after a biometry change —
    /// the safer default for a secret tied to "this specific person, right now".
    case biometryCurrentSet

    var secFlag: SecAccessControlCreateFlags {
        switch self {
        case .biometryCurrentSet: .biometryCurrentSet
        }
    }
}
