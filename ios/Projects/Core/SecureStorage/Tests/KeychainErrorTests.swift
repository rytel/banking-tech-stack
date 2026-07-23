import XCTest
import Security
@testable import CoreSecureStorage

final class KeychainErrorTests: XCTestCase {
    func test_mapsKnownStatusesToCases() {
        XCTAssertEqual(KeychainError(status: errSecItemNotFound), .itemNotFound)
        XCTAssertEqual(KeychainError(status: errSecDuplicateItem), .duplicateItem)
        XCTAssertEqual(KeychainError(status: errSecAuthFailed), .authenticationFailed)
        XCTAssertEqual(KeychainError(status: errSecUserCanceled), .userCancelled)
        XCTAssertEqual(KeychainError(status: errSecInteractionNotAllowed), .interactionNotAllowed)
    }

    func test_mapsUnknownStatusToUnhandledError() {
        let status: OSStatus = -99_999
        XCTAssertEqual(KeychainError(status: status), .unhandledError(status: status))
    }
}
