package topics

import "testing"

func TestService_List(t *testing.T) {
	svc := NewService()

	if got := svc.List(); len(got) == 0 {
		t.Fatal("expected at least one topic")
	}
}

func TestService_Get(t *testing.T) {
	svc := NewService()

	topic, err := svc.Get("1")
	if err != nil {
		t.Fatalf("Get(1): %v", err)
	}
	if topic.ID != "1" {
		t.Fatalf("expected topic id 1, got %q", topic.ID)
	}

	if _, err := svc.Get("does-not-exist"); err == nil {
		t.Fatal("expected error for unknown topic id")
	}
}
