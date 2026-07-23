// Package models holds shared data structures used across packages
// (e.g. Topic, TokenPair). It must not import handlers, auth, or topics.
package models

// Topic is a single "topic to review" item served by the API.
type Topic struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

// TokenPair is returned after a successful login or refresh.
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
}

// AccessTokenResponse is returned by the refresh endpoint. The refresh
// token itself is rotated too, so the client must store the new one.
type AccessTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
}

// LoginRequest is the body of POST /auth/login.
type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// RefreshRequest is the body of POST /auth/refresh.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// ErrorResponse is the JSON body returned for any failed request.
type ErrorResponse struct {
	Error string `json:"error"`
}

// TickerMessage is one message pushed over the /ws/ticker WebSocket stream.
type TickerMessage struct {
	ServerTime string `json:"server_time"`
}
