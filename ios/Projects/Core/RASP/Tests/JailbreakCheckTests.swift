import XCTest
@testable import CoreRASP

private final class FakeFileChecker: FileExistenceChecking {
    var existingPaths: Set<String> = []
    var allowsWriteOutsideSandbox = false
    private(set) var removedPaths: [String] = []

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }

    func createFile(atPath path: String, contents: Data?) -> Bool {
        allowsWriteOutsideSandbox
    }

    func removeItem(atPath path: String) throws {
        removedPaths.append(path)
    }
}

final class JailbreakCheckTests: XCTestCase {
    func test_knownJailbreakPathPresent_reportsSuspicious() {
        let checker = FakeFileChecker()
        checker.existingPaths = ["/Applications/Cydia.app"]

        XCTAssertTrue(JailbreakCheck.suspiciousPathsExist(checker: checker, paths: JailbreakCheck.defaultSuspiciousPaths))
    }

    func test_noSuspiciousPaths_reportsNotSuspicious() {
        let checker = FakeFileChecker()

        XCTAssertFalse(JailbreakCheck.suspiciousPathsExist(checker: checker, paths: JailbreakCheck.defaultSuspiciousPaths))
    }

    func test_sandboxWriteSucceeds_reportsWritable() {
        let checker = FakeFileChecker()
        checker.allowsWriteOutsideSandbox = true

        XCTAssertTrue(JailbreakCheck.canWriteOutsideSandbox(checker: checker))
        XCTAssertEqual(checker.removedPaths.count, 1)
    }

    func test_sandboxWriteBlocked_reportsNotWritable() {
        let checker = FakeFileChecker()
        checker.allowsWriteOutsideSandbox = false

        XCTAssertFalse(JailbreakCheck.canWriteOutsideSandbox(checker: checker))
        XCTAssertTrue(checker.removedPaths.isEmpty)
    }

    func test_eitherSignalPresent_reportsLikelyJailbroken() {
        let onlySuspiciousPath = FakeFileChecker()
        onlySuspiciousPath.existingPaths = ["/Applications/Cydia.app"]
        XCTAssertTrue(JailbreakCheck.isLikelyJailbroken(checker: onlySuspiciousPath))

        let onlySandboxWrite = FakeFileChecker()
        onlySandboxWrite.allowsWriteOutsideSandbox = true
        XCTAssertTrue(JailbreakCheck.isLikelyJailbroken(checker: onlySandboxWrite))
    }

    func test_noSignals_reportsNotJailbroken() {
        let checker = FakeFileChecker()

        XCTAssertFalse(JailbreakCheck.isLikelyJailbroken(checker: checker))
    }
}
