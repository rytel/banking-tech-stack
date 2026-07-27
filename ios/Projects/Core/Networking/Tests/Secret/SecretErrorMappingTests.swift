import XCTest
@testable import CoreNetworking
import CoreModels

/// Verifies the full path stub -> HTTPClient -> repository: transport failures
/// must come out as typed domain errors, never as URLError or NetworkError.
final class SecretErrorMappingTests: XCTestCase {
    private var secret: SecretRepository!

    override func setUp() {
        super.setUp()
        secret = SecretRepository(urlSession: MockURLProtocol.session())
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func test_secret401_mapsToUnauthorized() async {
        stub(status: 401)

        await assertFetchSecretFails(with: .unauthorized)
    }

    func test_secret500_mapsToServerUnavailable() async {
        stub(status: 500)

        await assertFetchSecretFails(with: .serverUnavailable)
    }

    func test_secretBrokenJSON_mapsToInvalidData() async {
        stub(status: 200, body: "not json at all")

        await assertFetchSecretFails(with: .invalidData)
    }

    func test_secretNoInternet_mapsToOffline() async {
        stubFailure(.notConnectedToInternet)

        await assertFetchSecretFails(with: .offline)
    }

    func test_secretCancelled_mapsToCancelled() async {
        stubFailure(.cancelled)

        await assertFetchSecretFails(with: .cancelled)
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

    private func assertFetchSecretFails(
        with expected: SecretError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await secret.fetchSecret()
            XCTFail("Expected SecretError", file: file, line: line)
        } catch {
            XCTAssertEqual(error, expected, file: file, line: line)
        }
    }
}
