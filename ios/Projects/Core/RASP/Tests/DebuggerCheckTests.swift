import Darwin
import XCTest
@testable import CoreRASP

final class DebuggerCheckTests: XCTestCase {
    func test_pFlagWithTracedBit_reportsAttached() {
        let flagsWithTraced = P_TRACED | 0x1

        XCTAssertTrue(DebuggerCheck.isTraced(flags: flagsWithTraced))
    }

    func test_pFlagWithoutTracedBit_reportsNotAttached() {
        let flagsWithoutTraced: Int32 = 0x1

        XCTAssertFalse(DebuggerCheck.isTraced(flags: flagsWithoutTraced))
    }

    func test_zeroFlags_reportsNotAttached() {
        XCTAssertFalse(DebuggerCheck.isTraced(flags: 0))
    }
}
