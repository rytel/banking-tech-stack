package ticker

import (
	"testing"
	"time"
)

func TestBuildMessage_ShapesPayload(t *testing.T) {
	at := time.Date(2026, 7, 23, 10, 15, 3, 0, time.UTC)

	msg := BuildMessage(at)

	parsed, err := time.Parse(time.RFC3339, msg.ServerTime)
	if err != nil {
		t.Fatalf("ServerTime %q does not parse as RFC3339: %v", msg.ServerTime, err)
	}
	if !parsed.Equal(at) {
		t.Fatalf("expected %v, got %v", at, parsed)
	}
}
