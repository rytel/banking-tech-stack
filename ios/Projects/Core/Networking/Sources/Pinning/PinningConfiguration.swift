import Foundation

/// The pins accepted for one host. `pins` are SPKI hashes (see `SPKIHash`).
/// A production pin set should always contain at least two pins: the live
/// server key plus an offline backup key — see "Certificate pinning" in
/// `ios/NOTES.md` for the rotation procedure.
struct PinSet: Sendable, Equatable {
    let host: String
    let pins: Set<String>

    /// Lets the local self-signed certificate pass the system trust check by
    /// anchoring it to itself. Only ever `true` for `.local` in DEBUG builds;
    /// the delegate compiles the whole bypass path out of Release builds.
    let allowsSelfSigned: Bool
}

/// Pin sets for every host the app talks to, keyed by host name.
/// A host without a pin set is rejected — missing pins mean "fail closed",
/// never "no pinning".
struct PinningConfiguration: Sendable, Equatable {
    private let pinSets: [String: PinSet]

    init(pinSets: [PinSet]) {
        self.pinSets = Dictionary(uniqueKeysWithValues: pinSets.map { ($0.host, $0) })
    }

    func pinSet(forHost host: String) -> PinSet? {
        pinSets[host]
    }
}

extension APIEnvironment {
    /// Pins live next to the base URLs: one source of truth per environment.
    var pinningConfiguration: PinningConfiguration {
        switch self {
        case .local:
            #if DEBUG
            let allowsSelfSigned = true
            #else
            let allowsSelfSigned = false
            #endif
            return PinningConfiguration(pinSets: [
                PinSet(
                    host: "localhost",
                    // SPKI pin of `backend/certs/server.crt`. Rerunning
                    // `backend/scripts/gen-cert.sh` prints the new value —
                    // paste it here after regenerating the certificate.
                    pins: ["/P42bM2/DO6r1ZzWPItlK3PYJ4MdxwZLH0ZamDi9Uds="],
                    allowsSelfSigned: allowsSelfSigned
                ),
            ])
        case .production:
            // TODO: replace with real pins before any release. The host is a
            // placeholder, so these pins are too. Compute the primary pin from
            // the live server (`ios/scripts/spki-pin.sh --host <host>`) and the
            // backup pin from an offline backup key (`spki-pin.sh --key`).
            return PinningConfiguration(pinSets: [
                PinSet(
                    host: "api.example.com",
                    pins: [
                        "PLACEHOLDER-PRIMARY-PIN-REPLACE-BEFORE-RELEASE",
                        "PLACEHOLDER-BACKUP-PIN-REPLACE-BEFORE-RELEASE",
                    ],
                    allowsSelfSigned: false
                ),
            ])
        }
    }
}
