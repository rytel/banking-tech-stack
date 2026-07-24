import XCTest
@testable import CoreNetworking

/// The critical property: hashes computed by the app must equal the pins
/// computed by openssl (`ios/scripts/spki-pin.sh`). These tests prove the
/// ASN.1 SPKI header reconstruction is byte-correct for both supported key
/// types, and that unsupported key types fail closed.
final class SPKIHashTests: XCTestCase {
    func test_ecP256Certificate_hashMatchesOpensslPin() {
        XCTAssertEqual(SPKIHash.hash(of: PinningFixtures.ecP256Certificate), PinningFixtures.ecP256Pin)
    }

    func test_rsa2048Certificate_hashMatchesOpensslPin() {
        XCTAssertEqual(SPKIHash.hash(of: PinningFixtures.rsa2048Certificate), PinningFixtures.rsa2048Pin)
    }

    func test_unsupportedKeyType_returnsNil() {
        XCTAssertNil(SPKIHash.hash(of: PinningFixtures.ed25519Certificate))
    }

    func test_hashesOfTrust_returnsChainPins() {
        let trust = PinningFixtures.trust(for: PinningFixtures.ecP256Certificate)

        XCTAssertEqual(SPKIHash.hashes(of: trust), [PinningFixtures.ecP256Pin])
    }

    func test_hashesOfTrust_skipsUnsupportedKeyTypes() {
        let trust = PinningFixtures.trust(for: PinningFixtures.ed25519Certificate)

        XCTAssertEqual(SPKIHash.hashes(of: trust), [])
    }
}
