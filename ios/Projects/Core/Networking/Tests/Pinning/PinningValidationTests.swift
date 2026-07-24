import XCTest
@testable import CoreNetworking

/// Drives `PinningURLSessionDelegate.validate` directly with `SecTrust`
/// fixtures. `MockURLProtocol` cannot cover this code (no real TLS handshake
/// happens there), so pinning gets its own direct tests.
///
/// The fixtures are self-signed, so every positive case relies on
/// `allowsSelfSigned` (the DEBUG-only anchor path) — which is also exactly
/// how the `.local` environment works at runtime.
final class PinningValidationTests: XCTestCase {
    func test_matchingPin_selfSignedAllowed_passes() {
        let result = PinningURLSessionDelegate.validate(
            trust: PinningFixtures.trust(for: PinningFixtures.ecP256Certificate),
            host: "localhost",
            configuration: configuration(pins: [PinningFixtures.ecP256Pin])
        )

        XCTAssertTrue(result)
    }

    func test_backupPinOnlyMatch_passes() {
        let result = PinningURLSessionDelegate.validate(
            trust: PinningFixtures.trust(for: PinningFixtures.ecP256Certificate),
            host: "localhost",
            configuration: configuration(pins: ["bogus-primary-pin", PinningFixtures.ecP256Pin])
        )

        XCTAssertTrue(result)
    }

    func test_wrongPin_fails() {
        let result = PinningURLSessionDelegate.validate(
            trust: PinningFixtures.trust(for: PinningFixtures.ecP256Certificate),
            host: "localhost",
            configuration: configuration(pins: [PinningFixtures.rsa2048Pin])
        )

        XCTAssertFalse(result)
    }

    func test_hostWithoutPinSet_failsClosed() {
        let result = PinningURLSessionDelegate.validate(
            trust: PinningFixtures.trust(for: PinningFixtures.ecP256Certificate),
            host: "unpinned.example.com",
            configuration: configuration(pins: [PinningFixtures.ecP256Pin])
        )

        XCTAssertFalse(result)
    }

    func test_selfSignedNotAllowed_failsSystemEvaluation() {
        // Right pin, but the self-signed chain must already die in the
        // system trust evaluation when the DEBUG anchor path is off.
        let result = PinningURLSessionDelegate.validate(
            trust: PinningFixtures.trust(for: PinningFixtures.ecP256Certificate),
            host: "localhost",
            configuration: configuration(pins: [PinningFixtures.ecP256Pin], allowsSelfSigned: false)
        )

        XCTAssertFalse(result)
    }

    func test_hostnameMismatch_failsEvenWithMatchingPin() {
        // The certificate only names "localhost"; the SSL policy checks the
        // hostname even on the anchored self-signed path.
        let result = PinningURLSessionDelegate.validate(
            trust: PinningFixtures.trust(for: PinningFixtures.ecP256Certificate, host: "other.example.com"),
            host: "other.example.com",
            configuration: PinningConfiguration(pinSets: [
                PinSet(host: "other.example.com", pins: [PinningFixtures.ecP256Pin], allowsSelfSigned: true),
            ])
        )

        XCTAssertFalse(result)
    }

    func test_pinningFailure_isRecordedPerHost_andConsumedOnce() {
        let delegate = PinningURLSessionDelegate(
            configuration: configuration(pins: ["bogus"])
        )

        XCTAssertFalse(delegate.consumePinningFailure(forHost: "localhost"))

        delegate.recordPinningFailure(forHost: "localhost")

        XCTAssertFalse(delegate.consumePinningFailure(forHost: "other.example.com"))
        XCTAssertTrue(delegate.consumePinningFailure(forHost: "localhost"))
        XCTAssertFalse(delegate.consumePinningFailure(forHost: "localhost"))
    }

    // MARK: - Helpers

    private func configuration(pins: Set<String>, allowsSelfSigned: Bool = true) -> PinningConfiguration {
        PinningConfiguration(pinSets: [
            PinSet(host: "localhost", pins: pins, allowsSelfSigned: allowsSelfSigned),
        ])
    }
}
