import XCTest
import Foundation
@testable import CoreSecureStorage

final class KeychainSecureStorageTests: XCTestCase {
    private var service: String!
    private var storage: KeychainSecureStorage!
    private let item = KeychainItemDescriptor(key: "test.key")

    override func setUp() {
        super.setUp()
        // A unique service per test means real Keychain writes never collide with app data
        // or with each other.
        service = "tests.\(UUID().uuidString)"
        storage = KeychainSecureStorage(service: service)
        addTeardownBlock { [storage, item] in
            try? storage?.delete(for: item)
        }
    }

    func test_saveThenRead_roundTrips() throws {
        let payload = Data("hunter2".utf8)

        try storage.save(payload, for: item)
        let read = try storage.read(for: item)

        XCTAssertEqual(read, payload)
    }

    func test_read_returnsNil_whenItemMissing() throws {
        let read = try storage.read(for: item)
        XCTAssertNil(read)
    }

    func test_deleteThenRead_returnsNil() throws {
        try storage.save(Data("value".utf8), for: item)

        try storage.delete(for: item)
        let read = try storage.read(for: item)

        XCTAssertNil(read)
    }

    func test_saveTwice_overwritesExistingValue() throws {
        try storage.save(Data("first".utf8), for: item)
        try storage.save(Data("second".utf8), for: item)

        let read = try storage.read(for: item)

        XCTAssertEqual(read, Data("second".utf8))
    }
}
