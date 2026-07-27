/// The combined result of every RASP check, at the moment it was taken.
public struct RASPStatus: Equatable, Sendable {
    public let isDebuggerAttached: Bool
    public let isLikelyJailbroken: Bool
}

/// One entry point for every RASP (Runtime Application Self-Protection)
/// check in this module. Both checks are defense-in-depth signals, not
/// hard barriers: see `DebuggerCheck` and `JailbreakCheck` for why each one
/// individually can be bypassed on a compromised device.
public enum RASPCheck {
    public static func currentStatus() -> RASPStatus {
        RASPStatus(
            isDebuggerAttached: DebuggerCheck.isDebuggerAttached(),
            isLikelyJailbroken: JailbreakCheck.isLikelyJailbroken()
        )
    }
}
