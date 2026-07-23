package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"banking-tech-stack/backend/internal/auth"
	"banking-tech-stack/backend/internal/models"
	"banking-tech-stack/backend/internal/topics"
)

func newTestServer(t *testing.T) *httptest.Server {
	t.Helper()

	authSvc, err := auth.NewService()
	if err != nil {
		t.Fatalf("auth.NewService: %v", err)
	}
	return httptest.NewServer(NewRouter(authSvc, topics.NewService()))
}

func TestSecret_RequiresAuth(t *testing.T) {
	server := newTestServer(t)
	defer server.Close()

	resp, err := http.Get(server.URL + "/secret")
	if err != nil {
		t.Fatalf("GET /secret: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401 without a token, got %d", resp.StatusCode)
	}
}

func TestLoginThenSecret(t *testing.T) {
	server := newTestServer(t)
	defer server.Close()

	loginBody, _ := json.Marshal(models.LoginRequest{Username: "demo", Password: "demo1234"})
	resp, err := http.Post(server.URL+"/auth/login", "application/json", bytes.NewReader(loginBody))
	if err != nil {
		t.Fatalf("POST /auth/login: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 from login, got %d", resp.StatusCode)
	}

	var tokens models.TokenPair
	if err := json.NewDecoder(resp.Body).Decode(&tokens); err != nil {
		t.Fatalf("decode login response: %v", err)
	}

	req, err := http.NewRequest(http.MethodGet, server.URL+"/secret", nil)
	if err != nil {
		t.Fatalf("build request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+tokens.AccessToken)

	secretResp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET /secret: %v", err)
	}
	defer secretResp.Body.Close()

	if secretResp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 with a valid token, got %d", secretResp.StatusCode)
	}
}

func TestGetTopic_NotFound(t *testing.T) {
	server := newTestServer(t)
	defer server.Close()

	resp, err := http.Get(server.URL + "/topics/does-not-exist")
	if err != nil {
		t.Fatalf("GET /topics/does-not-exist: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("expected 404, got %d", resp.StatusCode)
	}
}
