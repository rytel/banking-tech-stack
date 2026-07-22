package auth

import (
	"context"
	"net/http"
	"strings"
)

type contextKey string

const userIDContextKey contextKey = "userID"

// Middleware returns an HTTP middleware that requires a valid
// "Authorization: Bearer <token>" header. On success, the token's
// subject (user id) is stored in the request context.
func (s *Service) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || token == "" {
			http.Error(w, `{"error":"missing bearer token"}`, http.StatusUnauthorized)
			return
		}

		claims, err := s.VerifyAccessToken(token)
		if err != nil {
			http.Error(w, `{"error":"invalid or expired token"}`, http.StatusUnauthorized)
			return
		}

		ctx := context.WithValue(r.Context(), userIDContextKey, claims.Subject)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// UserID extracts the authenticated user id from the request
// context. It only returns a value inside handlers wrapped by
// Middleware.
func UserID(r *http.Request) (string, bool) {
	id, ok := r.Context().Value(userIDContextKey).(string)
	return id, ok
}
