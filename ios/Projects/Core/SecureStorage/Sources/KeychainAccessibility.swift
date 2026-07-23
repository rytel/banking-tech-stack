import Security

/// Only the `kSecAttrAccessible*` constants this app actually uses.
/// `.afterFirstUnlockThisDeviceOnly` is kept only as a contrasting case, so the
/// choice of `.whenUnlockedThisDeviceOnly` for the refresh token is visible in code.
public enum KeychainAccessibility: Sendable {
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly

    var secAttrValue: CFString {
        switch self {
        case .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}
