package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/coder/websocket"

	"banking-tech-stack/backend/internal/ticker"
)

// tickerHandler upgrades the connection to a WebSocket and pushes one
// message per second until the client disconnects.
func tickerHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		conn, err := websocket.Accept(w, r, nil)
		if err != nil {
			return
		}
		defer conn.CloseNow()

		// r.Context() is cancelled by net/http as soon as the client
		// disconnects, so this loop never outlives the request and no
		// separate goroutine is needed to watch for disconnects.
		ctx := r.Context()

		t := time.NewTicker(time.Second)
		defer t.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case now := <-t.C:
				data, err := json.Marshal(ticker.BuildMessage(now))
				if err != nil {
					return
				}
				if err := writeWithTimeout(ctx, conn, data); err != nil {
					return
				}
			}
		}
	}
}

func writeWithTimeout(ctx context.Context, conn *websocket.Conn, data []byte) error {
	writeCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	return conn.Write(writeCtx, websocket.MessageText, data)
}
