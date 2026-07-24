import Foundation

/// A real OSStatus -> typed-error mapping, not an opaque wrapper around whatever the
/// Security framework returns.
public enum KeychainError: Error, Equatable, Sendable {
    case itemNotFound
    case duplicateItem
    case authenticationFailed
    case userCancelled
    case interactionNotAllowed
    case accessControlCreationFailed
    case unexpectedData
    case unhandledError(status: OSStatus)

    init(status: OSStatus) {
        switch status {
        case errSecItemNotFound: self = .itemNotFound
        case errSecDuplicateItem: self = .duplicateItem
        case errSecAuthFailed: self = .authenticationFailed
        case errSecUserCanceled: self = .userCancelled
        case errSecInteractionNotAllowed: self = .interactionNotAllowed
        default: self = .unhandledError(status: status)
        }
    }
}
