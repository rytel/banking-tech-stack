import Foundation
import Security

/// Rejects TLS connections whose certificate chain does not contain a pinned
/// SPKI hash. URLSession routes server-trust challenges for both HTTPS and
/// WSS (WebSocket) through this delegate, so one pinned session covers all
/// traffic in the app.
///
/// Pinning is applied *in addition to* the system trust evaluation, never
/// instead of it: the chain, hostname and expiry checks run first, and only
/// then is the pin compared. A failed pin cancels the handshake before any
/// request data is sent.
///
/// All stored state is immutable, so the class is safe to use from
/// URLSession's delegate queue — hence `@unchecked Sendable` (an `NSObject`
/// subclass cannot conform to plain `Sendable`).
final class PinningURLSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let configuration: PinningConfiguration

    /// Cancelling a challenge surfaces as a generic `URLError.cancelled`,
    /// which is indistinguishable from a user-initiated cancel. The delegate
    /// therefore records which hosts failed pinning, so `HTTPClient` can map
    /// that cancel to `NetworkError.pinningFailure`. Guarded by `lock`.
    private var hostsWithPinningFailure: Set<String> = []
    private let lock = NSLock()

    init(configuration: PinningConfiguration) {
        self.configuration = configuration
    }

    /// Returns whether `host` recently failed pinning, and clears the flag.
    func consumePinningFailure(forHost host: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return hostsWithPinningFailure.remove(host) != nil
    }

    func recordPinningFailure(forHost host: String) {
        lock.lock()
        defer { lock.unlock() }
        hostsWithPinningFailure.insert(host)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only server-trust challenges carry a certificate chain to pin.
        // Other kinds (e.g. HTTP auth) keep their normal handling.
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        if Self.validate(trust: trust, host: host, configuration: configuration) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            recordPinningFailure(forHost: host)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// The whole pinning decision as a pure function, so tests can drive it
    /// with `SecTrust` fixtures without a live TLS handshake.
    static func validate(trust: SecTrust, host: String, configuration: PinningConfiguration) -> Bool {
        guard let pinSet = configuration.pinSet(forHost: host) else {
            // Unknown host: fail closed. Every host the app talks to must
            // have an explicit pin set.
            return false
        }

        guard passesSystemEvaluation(trust: trust, host: host, pinSet: pinSet) else {
            return false
        }

        // Accept when *any* certificate in the validated chain matches a pin.
        // This allows pinning either the leaf key or an intermediate CA key.
        let chainHashes = SPKIHash.hashes(of: trust)
        return !pinSet.pins.isDisjoint(with: chainHashes)
    }

    private static func passesSystemEvaluation(trust: SecTrust, host: String, pinSet: PinSet) -> Bool {
        SecTrustSetPolicies(trust, SecPolicyCreateSSL(true, host as CFString))
        if SecTrustEvaluateWithError(trust, nil) {
            return true
        }

        #if DEBUG
        // Local development uses a self-signed certificate that no system
        // root can vouch for. Anchoring the certificate to itself keeps the
        // hostname and expiry checks active and skips only the
        // "unknown root" failure. This path does not exist in Release builds.
        if pinSet.allowsSelfSigned,
            let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
            let leaf = chain.first {
            SecTrustSetAnchorCertificates(trust, [leaf] as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, true)
            return SecTrustEvaluateWithError(trust, nil)
        }
        #endif

        return false
    }
}
