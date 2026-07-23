import XCTest
@testable import CoreNetworking

final class CoreNetworkingTests: XCTestCase {
    func test_authRepositoryConformsToProtocol() {
        _ = AuthRepository()
    }

    func test_topicsRepositoryConformsToProtocol() {
        _ = TopicsRepository()
    }
}
