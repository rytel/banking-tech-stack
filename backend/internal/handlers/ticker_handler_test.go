package handlers

import (
	"context"
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"banking-tech-stack/backend/internal/models"
)

func TestTicker_StreamsAdvancingServerTime(t *testing.T) {
	server := newTestServer(t)
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws/ticker"

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	conn, _, err := websocket.Dial(ctx, wsURL, nil)
	if err != nil {
		t.Fatalf("Dial: %v", err)
	}
	defer conn.CloseNow()

	first := readMessage(t, ctx, conn)
	second := readMessage(t, ctx, conn)

	if !second.After(first) {
		t.Fatalf("expected second timestamp %v to be after first %v", second, first)
	}
}

func readMessage(t *testing.T, ctx context.Context, conn *websocket.Conn) time.Time {
	t.Helper()

	_, data, err := conn.Read(ctx)
	if err != nil {
		t.Fatalf("Read: %v", err)
	}

	var msg models.TickerMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("unmarshal %q: %v", data, err)
	}

	parsed, err := time.Parse(time.RFC3339, msg.ServerTime)
	if err != nil {
		t.Fatalf("parse server_time %q: %v", msg.ServerTime, err)
	}
	return parsed
}
