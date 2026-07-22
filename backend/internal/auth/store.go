package auth

import (
	"crypto/rand"
	"encoding/base64"
	"sync"
	"time"
)

const refreshTokenTTL = 24 * time.Hour

type refreshEntry struct {
	userID    string
	expiresAt time.Time
}

// refreshStore keeps active refresh tokens in memory. It is safe for
// concurrent use. Tokens are cleared on server restart, which is
// fine for a training project without a database.
type refreshStore struct {
	mu     sync.Mutex
	tokens map[string]refreshEntry
}

func newRefreshStore() *refreshStore {
	return &refreshStore{tokens: make(map[string]refreshEntry)}
}

func (s *refreshStore) issue(userID string) (string, error) {
	token, err := randomToken()
	if err != nil {
		return "", err
	}

	s.mu.Lock()
	s.tokens[token] = refreshEntry{userID: userID, expiresAt: time.Now().Add(refreshTokenTTL)}
	s.mu.Unlock()

	return token, nil
}

// consume validates a refresh token and invalidates it (rotation),
// returning the user id it belonged to.
func (s *refreshStore) consume(token string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	entry, ok := s.tokens[token]
	if !ok {
		return "", ErrInvalidToken
	}
	delete(s.tokens, token)

	if time.Now().After(entry.expiresAt) {
		return "", ErrExpiredToken
	}
	return entry.userID, nil
}

func randomToken() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}
