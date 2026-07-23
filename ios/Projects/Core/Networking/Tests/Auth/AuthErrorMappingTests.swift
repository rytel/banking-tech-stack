import XCTest
@testable import CoreNetworking
import CoreModels

/// Verifies the full path stub -> HTTPClient -> repository: transport failures
/// must come out as typed domain errors, never as URLError or NetworkError.
final class AuthErrorMappingTests: XCTestCase {
    private var auth: AuthRepository!

    override func setUp() {
        super.setUp()
        auth = AuthRepository(urlSession: MockURLProtocol.session())
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
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
}
