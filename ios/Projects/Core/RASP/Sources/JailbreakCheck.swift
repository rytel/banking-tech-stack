import Foundation

/// Abstracts the filesystem checks `JailbreakCheck` needs, so tests can
/// simulate a jailbroken filesystem without touching the real one.
protocol FileExistenceChecking {
    func fileExists(atPath path: String) -> Bool
    func createFile(atPath path: String, contents: Data?) -> Bool
    func removeItem(atPath path: String) throws
}

extension FileManager: FileExistenceChecking {
    // `FileManager.createFile(atPath:contents:)` really takes a third
    // `attributes` parameter (defaulted in the overlay, but still part of
    // the method's actual signature) so it can't satisfy the protocol
    // requirement directly. This forwards to it explicitly.
    func createFile(atPath path: String, contents: Data?) -> Bool {
        createFile(atPath: path, contents: contents, attributes: nil)
    }
}

/// A basic, heuristic jailbreak check: it looks for files and directories
/// that common jailbreak tools (Cydia, MobileSubstrate, apt) leave behind,
/// and tries to write outside the app sandbox.
///
/// This is a low-effort trip-wire, not a bypass-proof jailbreak detector. A
/// determined jailbreak can hide these paths (file-hooking tweaks exist
/// specifically for this) or block the sandbox-escape write. Treat a
/// positive result as one signal among several, and never as a hard
/// security barrier — the same defense-in-depth caveat as `DebuggerCheck`.
public enum JailbreakCheck {
    static let defaultSuspiciousPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/private/var/lib/apt",
    ]

    /// Checks whether any known jailbreak-tool path exists on disk. These
    /// paths are absent on a stock, non-jailbroken iOS install.
    static func suspiciousPathsExist(
        checker: FileExistenceChecking = FileManager.default,
        paths: [String] = defaultSuspiciousPaths
    ) -> Bool {
        paths.contains { checker.fileExists(atPath: $0) }
    }

    /// A sandboxed app can never write outside its container. Succeeding to
    /// write to `/private` is a strong signal the sandbox has been broken.
    static func canWriteOutsideSandbox(
        checker: FileExistenceChecking = FileManager.default,
        testPath: String = "/private/rasp_sandbox_check.txt"
    ) -> Bool {
        let didWrite = checker.createFile(atPath: testPath, contents: Data("rasp".utf8))
        if didWrite {
            try? checker.removeItem(atPath: testPath)
        }
        return didWrite
    }

    /// Combines both signals: either one is enough to flag the device as
    /// likely jailbroken.
    public static func isLikelyJailbroken() -> Bool {
        isLikelyJailbroken(checker: FileManager.default)
    }

    /// Same check, with an injectable checker for tests.
    static func isLikelyJailbroken(checker: FileExistenceChecking) -> Bool {
        suspiciousPathsExist(checker: checker) || canWriteOutsideSandbox(checker: checker)
    }
}
