import XCTest
@testable import CoreSecureStorage

final class CoreSecureStorageTests: XCTestCase {
    func test_keychainSecureStorageConformsToProtocol() {
        let storage: SecureStorageProtocol = KeychainSecureStorage()
        XCTAssertNotNil(storage)
    }
}
