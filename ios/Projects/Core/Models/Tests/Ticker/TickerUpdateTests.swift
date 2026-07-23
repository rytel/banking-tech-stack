import XCTest
@testable import CoreModels

final class TickerUpdateTests: XCTestCase {
    func test_decodesSnakeCaseServerTime() throws {
        let json = Data(#"{"server_time":"2026-07-23T10:15:03Z"}"#.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let update = try decoder.decode(TickerUpdate.self, from: json)

        XCTAssertEqual(update.serverTime, "2026-07-23T10:15:03Z")
    }
}
