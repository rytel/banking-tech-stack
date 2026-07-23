package auth

import (
	"testing"
	"time"
)

func TestSignAndVerifyAccessToken_RoundTrip(t *testing.T) {
	key, err := generateSigningKey()
	if err != nil {
		t.Fatalf("generateSigningKey: %v", err)
	}

	token, expiresAt, err := issueAccessToken(key, "demo")
	if err != nil {
		t.Fatalf("issueAccessToken: %v", err)
	}
	if expiresAt.Before(time.Now()) {
		t.Fatalf("expected expiry in the future, got %v", expiresAt)
	}

	claims, err := verifyAccessToken(&key.PublicKey, token)
	if err != nil {
		t.Fatalf("verifyAccessToken: %v", err)
	}
	if claims.Subject != "demo" {
		t.Fatalf("expected subject %q, got %q", "demo", claims.Subject)
	}
}

func TestVerifyAccessToken_RejectsWrongKey(t *testing.T) {
	key, err := generateSigningKey()
	if err != nil {
		t.Fatalf("generateSigningKey: %v", err)
	}
	otherKey, err := generateSigningKey()
	if err != nil {
		t.Fatalf("generateSigningKey: %v", err)
	}

	token, _, err := issueAccessToken(key, "demo")
	if err != nil {
		t.Fatalf("issueAccessToken: %v", err)
	}

	if _, err := verifyAccessToken(&otherKey.PublicKey, token); err == nil {
		t.Fatal("expected verification with the wrong public key to fail")
	}
}
