import XCTest
@testable import CoreNetworking
import CoreModels

final class TickerErrorMappingTests: XCTestCase {
    func test_noInternet_mapsToOffline() {
        XCTAssertEqual(TickerError(URLError(.notConnectedToInternet)), .offline)
    }

    func test_cancelled_mapsToCancelled() {
        XCTAssertEqual(TickerError(URLError(.cancelled)), .cancelled)
    }

    func test_otherURLError_mapsToConnectionFailed() {
        XCTAssertEqual(TickerError(URLError(.badServerResponse)), .connectionFailed)
    }
}
