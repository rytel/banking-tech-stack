// Package auth handles login, token issuing (JWT ES256), refresh,
// and the authorization middleware. No other package should
// duplicate this logic.
package auth

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"fmt"
)

// generateSigningKey creates a fresh ES256 (P-256) key pair.
//
// The key lives only in memory and is regenerated on every server
// restart. That means existing tokens become invalid on restart,
// which is fine for a training project without a database. In a
// real system the private key would be loaded from a secret store.
func generateSigningKey() (*ecdsa.PrivateKey, error) {
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, fmt.Errorf("generate ES256 key: %w", err)
	}
	return key, nil
}
