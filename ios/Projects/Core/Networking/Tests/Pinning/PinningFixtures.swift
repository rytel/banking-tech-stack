import Foundation
import Security

/// Self-signed test certificates (CN=localhost) embedded as base64 DER,
/// together with their expected SPKI pins computed with
/// `ios/scripts/spki-pin.sh --cert`.
///
/// The certificates are backdated (issued 2019, expiring 2039) on purpose:
/// Apple's TLS policy limits certificates issued after mid-2019 to a short
/// maximum validity, so a long-lived fixture must predate that rule or the
/// tests would start failing within about a year. Regenerate with:
///
///   openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
///     -keyout ec.key -out ec.crt -nodes \
///     -not_before 20190101000000Z -not_after 20390101000000Z \
///     -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost" \
///     -addext "extendedKeyUsage=serverAuth"
///
/// (swap `-newkey rsa:2048` / `-newkey ed25519` for the other two), then
/// re-embed `openssl x509 -in <cert> -outform der | base64` and the new pins.
enum PinningFixtures {
    /// EC P-256 — a supported key type.
    static let ecP256Certificate = certificate(fromBase64DER: """
        MIIBqTCCAU6gAwIBAgIUTAilLRPpV7IaVVT8718rEvCAioUwCgYIKoZIzj0EAwIwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4X\
        DTE5MDEwMTAwMDAwMFoXDTM5MDEwMTAwMDAwMFowFDESMBAGA1UEAwwJbG9jYWxob3N0MFkwEwYHKoZIzj0CAQYIKoZIzj0D\
        AQcDQgAEgbSe0jryLm3ZS6nKCJT0ABSYaJpIlkQpIeprXdy3FoP4oZuYQH10PnyDb580Jl+UBhlrkym6C+JGBvT0SkyGAqN+\
        MHwwHQYDVR0OBBYEFD++20cR8A06CmgRhyj3tzHcGhVKMB8GA1UdIwQYMBaAFD++20cR8A06CmgRhyj3tzHcGhVKMA8GA1Ud\
        EwEB/wQFMAMBAf8wFAYDVR0RBA0wC4IJbG9jYWxob3N0MBMGA1UdJQQMMAoGCCsGAQUFBwMBMAoGCCqGSM49BAMCA0kAMEYC\
        IQC723slW7PKbzR/gyR3rEB0qEX0U7Hb/yyF4mj7H1gfegIhALzwZEJaQagpPJckIthvEdalADv9uREX6dXtZRiv7Ie1
        """)
    static let ecP256Pin = "78NpF0N+osU5Q3KPFaVFR/dwGwol3M2M1myX2ZayE8k="

    /// RSA-2048 — the other supported key type.
    static let rsa2048Certificate = certificate(fromBase64DER: """
        MIIDNDCCAhygAwIBAgIUBfN+hTrO0D3nYhHa5sk5XXde/rkwDQYJKoZIhvcNAQELBQAwFDESMBAGA1UEAwwJbG9jYWxob3N0\
        MB4XDTE5MDEwMTAwMDAwMFoXDTM5MDEwMTAwMDAwMFowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEF\
        AAOCAQ8AMIIBCgKCAQEAsprw4We9PuYQ3YblghROPiWAXO0YeuDuhaXMLjcUMPyvkPN5l3lcYCtWy9JukBARW4kkqodYNVuL\
        a0cKz0H8dQBpYsUjSG9ToS9qCDJi2PU1xjwaS0OOqPZUjHWJp8h69WABy4mIpLu5bQwTVx2isDnsMFAB/ZwUaNAhGeHB6tXV\
        JTRszCFJbcBmaMmOTSBqPvXLmvQdgQ0c5qXh4E7NJJseuLlcjly3TZuWDKw3/8hkzYvD092ilCimJ/oq6hrMtGU0H8LHddlk\
        Qs1YYP07eqOY0AIC1j0jE4gEv2qSMlPKW2dgBp4TGvwGrSkxBVRxxwKsZPyBx/X0VktXcAGMewIDAQABo34wfDAdBgNVHQ4E\
        FgQUngk/cJsLk9szHychHu0/bwcx284wHwYDVR0jBBgwFoAUngk/cJsLk9szHychHu0/bwcx284wDwYDVR0TAQH/BAUwAwEB\
        /zAUBgNVHREEDTALgglsb2NhbGhvc3QwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDQYJKoZIhvcNAQELBQADggEBADKgmCB8uLoX\
        sXaWVNBwI8YMtUWiy/eWvzJiPLBaMB04P0pRcXJ8DQOxPgYdvwZlc/a3XQ8BqfZ3UZB62Q001a53tfwyLnTU0vr0VNY3idNd\
        119ySeIfWeYVfFgBk8m7NXInpt9tbRvDSGFFUgQ1xXblNvmrgoDd39XcM0a61mc3VVzuZBtU9VtVa+RTfP/D3am19zvo5d86\
        osBV23HjlhuaxDjOPvRtbnmU8KrN/59IsH3G5iAXA8j454Sa5jloHDrMKyEHozz2OXe3Xo8jHXtW2wJFzNKxMld185J292lx\
        uZTgYtez5/0FAlcy1qn+Y4an1xKS9Ghc9V/RP8wQ3wI=
        """)
    static let rsa2048Pin = "+qxQ4aJzFTyjXo+AJmOLmJrNLnzlVJMVz4niYTVKyn0="

    /// Ed25519 — deliberately outside the supported key types, so hashing it
    /// must fail closed (return nil).
    static let ed25519Certificate = certificate(fromBase64DER: """
        MIIBaDCCARqgAwIBAgIUGwegWOIWWcbPfyKX9k/keXUnpg4wBQYDK2VwMBQxEjAQBgNVBAMMCWxvY2FsaG9zdDAeFw0xOTAx\
        MDEwMDAwMDBaFw0zOTAxMDEwMDAwMDBaMBQxEjAQBgNVBAMMCWxvY2FsaG9zdDAqMAUGAytlcAMhAOL44KqXW1icPL41XO5w\
        hcvH6IVyBcO2oJI91l8ID4MNo34wfDAdBgNVHQ4EFgQUvEf8IPaSyE8BcRkop/IIEEzF7ZUwHwYDVR0jBBgwFoAUvEf8IPaS\
        yE8BcRkop/IIEEzF7ZUwDwYDVR0TAQH/BAUwAwEB/zAUBgNVHREEDTALgglsb2NhbGhvc3QwEwYDVR0lBAwwCgYIKwYBBQUH\
        AwEwBQYDK2VwA0EAnXMDxwmFT7HvoQpNKj/lWgSYvm8YbXERPxtOWizj1bfIlbrbqjLTJhPFHqPMe548hYf8GdJI3YZW3jai\
        gazwCw==
        """)

    /// Builds a `SecTrust` for one certificate against the SSL policy for
    /// `host` — the same shape the pinning delegate receives at runtime.
    static func trust(for certificate: SecCertificate, host: String = "localhost") -> SecTrust {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(
            certificate,
            SecPolicyCreateSSL(true, host as CFString),
            &trust
        )
        precondition(status == errSecSuccess, "Could not create SecTrust for fixture")
        return trust!
    }

    private static func certificate(fromBase64DER base64: String) -> SecCertificate {
        guard
            let der = Data(base64Encoded: base64),
            let certificate = SecCertificateCreateWithData(nil, der as CFData)
        else {
            preconditionFailure("Fixture certificate is not valid DER")
        }
        return certificate
    }
}
