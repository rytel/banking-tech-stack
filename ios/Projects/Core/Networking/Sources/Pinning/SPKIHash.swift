import CryptoKit
import Foundation
import Security

/// Computes certificate pins in the standard SPKI format:
/// base64(SHA-256(DER-encoded SubjectPublicKeyInfo)).
///
/// This is the same value that `openssl` produces with:
/// `openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`
/// so pins computed by `ios/scripts/spki-pin.sh` match the app byte for byte.
enum SPKIHash {
    /// `SecKeyCopyExternalRepresentation` returns the raw key bytes *without*
    /// the ASN.1 SubjectPublicKeyInfo header. We put the fixed header back
    /// before hashing, so our hashes match openssl-computed pins. Each key
    /// type and size has its own fixed header. Only the key types below are
    /// supported; anything else hashes to `nil`, which callers treat as
    /// "no match" (fail closed) — the allowlist doubles as a key policy.
    private static let ecP256Header: [UInt8] = [
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce,
        0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d,
        0x03, 0x01, 0x07, 0x03, 0x42, 0x00,
    ]

    private static let rsa2048Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86,
        0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03,
        0x82, 0x01, 0x0f, 0x00,
    ]

    /// Returns the SPKI pin of one certificate, or `nil` when the key type
    /// is not supported.
    static func hash(of certificate: SecCertificate) -> String? {
        guard
            let key = SecCertificateCopyKey(certificate),
            let header = spkiHeader(for: key),
            let rawKey = SecKeyCopyExternalRepresentation(key, nil) as Data?
        else {
            return nil
        }

        var spki = Data(header)
        spki.append(rawKey)
        return Data(SHA256.hash(data: spki)).base64EncodedString()
    }

    /// Returns the SPKI pins of every certificate in the evaluated chain,
    /// leaf first. Certificates with unsupported key types are skipped.
    static func hashes(of trust: SecTrust) -> [String] {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
            return []
        }
        return chain.compactMap(hash(of:))
    }

    private static func spkiHeader(for key: SecKey) -> [UInt8]? {
        guard
            let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
            let keyType = attributes[kSecAttrKeyType] as? String,
            let keySize = attributes[kSecAttrKeySizeInBits] as? Int
        else {
            return nil
        }

        if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String), keySize == 256 {
            return ecP256Header
        }
        if keyType == (kSecAttrKeyTypeRSA as String), keySize == 2048 {
            return rsa2048Header
        }
        return nil
    }
}
