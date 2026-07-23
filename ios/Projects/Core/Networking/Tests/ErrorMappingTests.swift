import XCTest
@testable import CoreNetworking
import CoreModels

/// Verifies the full path stub -> HTTPClient -> repository: transport failures
/// must come out as typed domain errors, never as URLError or NetworkError.
final class ErrorMappingTests: XCTestCase {
    private var topics: TopicsRepository!
    private var auth: AuthRepository!

    override func setUp() {
        super.setUp()
        let session = MockURLProtocol.session()
        topics = TopicsRepository(urlSession: session)
        auth = AuthRepository(urlSession: session)
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    // MARK: - Status codes -> TopicsError

    func test_topics401_mapsToUnauthorized() async {
        stub(status: 401)

        await assertFetchTopicsFails(with: .unauthorized)
    }

    func test_topic404_mapsToTopicNotFound() async {
        stub(status: 404)

        do {
            _ = try await topics.fetchTopic(id: "42")
            XCTFail("Expected TopicsError")
        } catch {
            XCTAssertEqual(error, .topicNotFound)
        }
    }

    func test_topics500_mapsToServerUnavailable() async {
        stub(status: 500)

        await assertFetchTopicsFails(with: .serverUnavailable)
    }

    func test_topicsBrokenJSON_mapsToInvalidData() async {
        stub(status: 200, body: "not json at all")

        await assertFetchTopicsFails(with: .invalidData)
    }

    // MARK: - Connection failures -> TopicsError

    func test_topicsNoInternet_mapsToOffline() async {
        stubFailure(.notConnectedToInternet)

        await assertFetchTopicsFails(with: .offline)
    }

    func test_topicsCancelled_mapsToCancelled() async {
        stubFailure(.cancelled)

        await assertFetchTopicsFails(with: .cancelled)
    }

    // MARK: - The same 401 has a different domain meaning per auth operation

    func test_login401_mapsToInvalidCredentials() async {
        stub(status: 401)

        do {
            _ = try await auth.login(username: "user", password: "wrong")
            XCTFail("Expected AuthError")
        } catch {
            XCTAssertEqual(error, .invalidCredentials)
        }
    }

    func test_refresh401_mapsToSessionExpired() async {
        stub(status: 401)

        do {
            _ = try await auth.refresh(refreshToken: "expired")
            XCTFail("Expected AuthError")
        } catch {
            XCTAssertEqual(error, .sessionExpired)
        }
    }

    // MARK: - Helpers

    private func stub(status: Int, body: String = "{}") {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(body.utf8))
        }
    }

    private func stubFailure(_ code: URLError.Code) {
        MockURLProtocol.handler = { _ in throw URLError(code) }
    }

    private func assertFetchTopicsFails(
        with expected: TopicsError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await topics.fetchTopics()
            XCTFail("Expected TopicsError", file: file, line: line)
        } catch {
            // Typed throws: `error` is already a `TopicsError`, no cast needed.
            XCTAssertEqual(error, expected, file: file, line: line)
        }
    }
}
