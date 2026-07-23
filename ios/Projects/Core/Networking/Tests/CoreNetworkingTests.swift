import XCTest
@testable import CoreNetworking

final class CoreNetworkingTests: XCTestCase {
    private let client = HTTPClient(environment: .local)

    func test_authRepositoryConformsToProtocol() {
        _ = AuthRepository()
    }

    func test_topicsRepositoryConformsToProtocol() {
        _ = TopicsRepository()
    }

    func test_loginRequest_targetsLocalBaseURLWithPort() throws {
        let request = try client.urlRequest(for: AuthAPI.login(username: "user", password: "secret"))

        XCTAssertEqual(request.url?.absoluteString, "https://localhost:8443/auth/login")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_refreshRequest_encodesBodyAsSnakeCase() throws {
        let request = try client.urlRequest(for: AuthAPI.refresh(token: "abc"))

        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(json, ["refresh_token": "abc"])
    }

    func test_topicRequest_buildsPathWithIdAndHasNoBody() throws {
        let request = try client.urlRequest(for: TopicsAPI.topic(id: "42"))

        XCTAssertEqual(request.url?.absoluteString, "https://localhost:8443/topics/42")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }
}
