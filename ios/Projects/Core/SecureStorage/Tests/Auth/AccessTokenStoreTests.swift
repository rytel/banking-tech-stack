import XCTest
@testable import CoreSecureStorage

final class AccessTokenStoreTests: XCTestCase {
    func test_setThenRead_returnsToken() async {
        let store = AccessTokenStore()
        await store.set("access-123")
        let token = await store.currentToken()
        XCTAssertEqual(token, "access-123")
    }

    func test_setNil_clearsToken() async {
        let store = AccessTokenStore()
        await store.set("access-123")
        await store.set(nil)
        let token = await store.currentToken()
        XCTAssertNil(token)
    }

    func test_concurrentWrites_doNotCrash() async {
        let store = AccessTokenStore()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<100 {
                group.addTask { await store.set("token-\(index)") }
            }
        }
        let token = await store.currentToken()
        XCTAssertNotNil(token)
    }
}
