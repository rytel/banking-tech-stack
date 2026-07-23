import XCTest
@testable import CoreModels

final class TopicTests: XCTestCase {
    func test_storesGivenFields() {
        let topic = Topic(id: "1", title: "JWT", description: "Access and refresh tokens")

        XCTAssertEqual(topic.id, "1")
        XCTAssertEqual(topic.title, "JWT")
        XCTAssertEqual(topic.description, "Access and refresh tokens")
    }
}
