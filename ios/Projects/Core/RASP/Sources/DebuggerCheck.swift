import Darwin
import Foundation

/// Detects whether a debugger is attached to the current process, using the
/// classic `sysctl(KERN_PROC)` trick from Apple Technical Q&A QA1361.
///
/// This is defense-in-depth, not a hard barrier: it only reports the state at
/// the moment it is called (a debugger attached a moment later is invisible
/// to it), and on a jailbroken device the check itself can be hooked or
/// patched to always return `false`. Never make this the sole gate for a
/// security decision — treat it as one signal among several.
public enum DebuggerCheck {
    /// Pure bit-check, split out from the `sysctl` call so it can be tested
    /// with hand-built flag values instead of a real debugger attachment.
    static func isTraced(flags: Int32) -> Bool {
        (flags & P_TRACED) != 0
    }

    /// Reads the current process's `kinfo_proc` and checks the `P_TRACED`
    /// flag, which the kernel sets while a debugger (or `ptrace`) is attached.
    public static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard result == 0 else {
            // The syscall itself failing is not a signal either way; fail
            // to "not attached" rather than raising a false alarm.
            return false
        }

        return isTraced(flags: info.kp_proc.p_flag)
    }
}
