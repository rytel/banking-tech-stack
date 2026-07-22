// Package handlers wires HTTP routes to the auth and topics packages.
// It contains no business logic of its own.
package handlers

import (
	"net/http"

	"banking-tech-stack/backend/internal/auth"
	"banking-tech-stack/backend/internal/topics"
)

// NewRouter builds the full set of HTTP routes for the server.
func NewRouter(authSvc *auth.Service, topicsSvc *topics.Service) http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	mux.HandleFunc("POST /auth/login", loginHandler(authSvc))
	mux.HandleFunc("POST /auth/refresh", refreshHandler(authSvc))

	mux.HandleFunc("GET /topics", listTopicsHandler(topicsSvc))
	mux.HandleFunc("GET /topics/{id}", getTopicHandler(topicsSvc))

	mux.Handle("GET /secret", authSvc.Middleware(secretHandler()))

	return mux
}
