import XCTest
@testable import CoreSecureStorage

final class RefreshTokenStorageTests: XCTestCase {
    private var refreshStorage: KeychainRefreshTokenStorage!

    override func setUp() {
        super.setUp()
        let storage = KeychainSecureStorage(service: "tests.\(UUID().uuidString)")
        refreshStorage = KeychainRefreshTokenStorage(storage: storage)
        addTeardownBlock { [refreshStorage] in
            try? refreshStorage?.delete()
        }
    }

    func test_saveThenRead_roundTrips() throws {
        try refreshStorage.save("refresh-token-abc")
        XCTAssertEqual(try refreshStorage.read(), "refresh-token-abc")
    }

    func test_read_returnsNil_whenNothingSaved() throws {
        XCTAssertNil(try refreshStorage.read())
    }

    func test_delete_removesToken() throws {
        try refreshStorage.save("refresh-token-abc")
        try refreshStorage.delete()
        XCTAssertNil(try refreshStorage.read())
    }
}
