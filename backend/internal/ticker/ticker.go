// Package ticker builds the messages pushed over the /ws/ticker WebSocket stream.
package ticker

import (
	"time"

	"banking-tech-stack/backend/internal/models"
)

// BuildMessage formats the given time as a ticker message.
func BuildMessage(t time.Time) models.TickerMessage {
	return models.TickerMessage{ServerTime: t.UTC().Format(time.RFC3339)}
}
