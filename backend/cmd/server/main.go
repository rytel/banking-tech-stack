package main

import (
	"log"
	"net/http"

	"banking-tech-stack/backend/internal/auth"
	"banking-tech-stack/backend/internal/handlers"
	"banking-tech-stack/backend/internal/topics"
)

const (
	addr     = ":8443"
	certFile = "certs/server.crt"
	keyFile  = "certs/server.key"
)

func main() {
	authSvc, err := auth.NewService()
	if err != nil {
		log.Fatalf("could not create auth service: %v", err)
	}
	router := handlers.NewRouter(authSvc, topics.NewService())

	log.Printf("server listening on https://localhost%s", addr)
	log.Fatal(http.ListenAndServeTLS(addr, certFile, keyFile, router))
}
