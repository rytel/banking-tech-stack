package auth

import (
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"strings"
	"time"
)

const accessTokenTTL = 5 * time.Minute

var (
	// ErrInvalidToken means the token is malformed or its signature
	// does not match.
	ErrInvalidToken = errors.New("invalid token")
	// ErrExpiredToken means the token's signature is valid but it has
	// passed its expiry time.
	ErrExpiredToken = errors.New("token expired")
)

type jwtHeader struct {
	Alg string `json:"alg"`
	Typ string `json:"typ"`
}

// Claims are the JWT payload fields used for access tokens.
type Claims struct {
	Subject   string `json:"sub"`
	IssuedAt  int64  `json:"iat"`
	ExpiresAt int64  `json:"exp"`
}

// issueAccessToken builds and signs a short-lived JWT for the given
// user id. Signed with ES256: the private key never leaves the
// server, and clients only ever see the public key, unlike HS256
// where verifying the token would require sharing the same secret
// used to sign it.
func issueAccessToken(key *ecdsa.PrivateKey, userID string) (token string, expiresAt time.Time, err error) {
	now := time.Now()
	expiresAt = now.Add(accessTokenTTL)

	claims := Claims{
		Subject:   userID,
		IssuedAt:  now.Unix(),
		ExpiresAt: expiresAt.Unix(),
	}

	token, err = signClaims(key, claims)
	if err != nil {
		return "", time.Time{}, err
	}
	return token, expiresAt, nil
}

func signClaims(key *ecdsa.PrivateKey, claims Claims) (string, error) {
	headerJSON, err := json.Marshal(jwtHeader{Alg: "ES256", Typ: "JWT"})
	if err != nil {
		return "", fmt.Errorf("marshal header: %w", err)
	}
	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		return "", fmt.Errorf("marshal claims: %w", err)
	}

	signingInput := base64URLEncode(headerJSON) + "." + base64URLEncode(claimsJSON)

	hash := sha256.Sum256([]byte(signingInput))
	r, s, err := ecdsa.Sign(rand.Reader, key, hash[:])
	if err != nil {
		return "", fmt.Errorf("sign token: %w", err)
	}

	return signingInput + "." + base64URLEncode(encodeSignature(r, s)), nil
}

// verifyAccessToken checks a token's ES256 signature and expiry, and
// returns its claims.
func verifyAccessToken(pub *ecdsa.PublicKey, token string) (Claims, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return Claims{}, ErrInvalidToken
	}

	signingInput := parts[0] + "." + parts[1]
	hash := sha256.Sum256([]byte(signingInput))

	sig, err := base64URLDecode(parts[2])
	if err != nil || len(sig) != 64 {
		return Claims{}, ErrInvalidToken
	}
	r := new(big.Int).SetBytes(sig[:32])
	s := new(big.Int).SetBytes(sig[32:])

	if !ecdsa.Verify(pub, hash[:], r, s) {
		return Claims{}, ErrInvalidToken
	}

	claimsJSON, err := base64URLDecode(parts[1])
	if err != nil {
		return Claims{}, ErrInvalidToken
	}

	var claims Claims
	if err := json.Unmarshal(claimsJSON, &claims); err != nil {
		return Claims{}, ErrInvalidToken
	}

	if time.Now().Unix() > claims.ExpiresAt {
		return Claims{}, ErrExpiredToken
	}

	return claims, nil
}

// encodeSignature packs r and s into the fixed 32+32 byte layout
// JWS expects for ES256 (not the ASN.1 DER format ecdsa.Sign's
// sibling SignASN1 would produce).
func encodeSignature(r, s *big.Int) []byte {
	out := make([]byte, 64)
	r.FillBytes(out[:32])
	s.FillBytes(out[32:])
	return out
}

func base64URLEncode(b []byte) string {
	return base64.RawURLEncoding.EncodeToString(b)
}

func base64URLDecode(s string) ([]byte, error) {
	return base64.RawURLEncoding.DecodeString(s)
}
