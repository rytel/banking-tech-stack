package auth

import (
	"crypto/ecdsa"
	"crypto/subtle"
	"errors"
	"time"
)

// ErrInvalidCredentials is returned by Login when the username or
// password does not match the demo user.
var ErrInvalidCredentials = errors.New("invalid credentials")

// demoUsername and demoPassword are the only valid credentials. The
// content of this training project is irrelevant, so a real user
// store is out of scope.
const (
	demoUsername = "demo"
	demoPassword = "demo1234"
)

// Service issues and verifies tokens for a single hardcoded demo user.
type Service struct {
	privateKey *ecdsa.PrivateKey
	publicKey  *ecdsa.PublicKey
	refresh    *refreshStore
}

// NewService creates an auth service with a freshly generated ES256
// signing key.
func NewService() (*Service, error) {
	key, err := generateSigningKey()
	if err != nil {
		return nil, err
	}
	return &Service{
		privateKey: key,
		publicKey:  &key.PublicKey,
		refresh:    newRefreshStore(),
	}, nil
}

// Login checks the given credentials and, if valid, issues a fresh
// access/refresh token pair.
func (s *Service) Login(username, password string) (accessToken, refreshToken string, expiresIn int, err error) {
	validUsername := subtle.ConstantTimeCompare([]byte(username), []byte(demoUsername)) == 1
	validPassword := subtle.ConstantTimeCompare([]byte(password), []byte(demoPassword)) == 1
	if !validUsername || !validPassword {
		return "", "", 0, ErrInvalidCredentials
	}

	return s.issueTokenPair(demoUsername)
}

// Refresh validates a refresh token and, if valid, rotates it and
// issues a new access token.
func (s *Service) Refresh(refreshToken string) (accessToken, newRefreshToken string, expiresIn int, err error) {
	userID, err := s.refresh.consume(refreshToken)
	if err != nil {
		return "", "", 0, err
	}
	return s.issueTokenPair(userID)
}

func (s *Service) issueTokenPair(userID string) (accessToken, refreshToken string, expiresIn int, err error) {
	accessToken, expiresAt, err := issueAccessToken(s.privateKey, userID)
	if err != nil {
		return "", "", 0, err
	}

	refreshToken, err = s.refresh.issue(userID)
	if err != nil {
		return "", "", 0, err
	}

	return accessToken, refreshToken, int(time.Until(expiresAt).Seconds()), nil
}

// VerifyAccessToken checks a bearer token's signature and expiry.
func (s *Service) VerifyAccessToken(token string) (Claims, error) {
	return verifyAccessToken(s.publicKey, token)
}
