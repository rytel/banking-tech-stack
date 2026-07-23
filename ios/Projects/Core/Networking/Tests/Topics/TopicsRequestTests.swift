import XCTest
@testable import CoreNetworking

final class TopicsRequestTests: XCTestCase {
    private let client = HTTPClient(environment: .local)

    func test_topicsRepositoryConformsToProtocol() {
        _ = TopicsRepository()
    }

    func test_topicRequest_buildsPathWithIdAndHasNoBody() throws {
        let request = try client.urlRequest(for: TopicsAPI.topic(id: "42"))

        XCTAssertEqual(request.url?.absoluteString, "https://localhost:8443/topics/42")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    func test_topicsRequest_withoutQuery_hasNoQueryItems() throws {
        let request = try client.urlRequest(for: TopicsAPI.topics())

        XCTAssertEqual(request.url?.absoluteString, "https://localhost:8443/topics")
    }

    func test_topicsRequest_withQuery_addsQItem() throws {
        let request = try client.urlRequest(for: TopicsAPI.topics(query: "jwt"))

        XCTAssertEqual(request.url?.absoluteString, "https://localhost:8443/topics?q=jwt")
    }
}
