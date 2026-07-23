package topics

import "testing"

func TestService_List(t *testing.T) {
	svc := NewService()

	if got := svc.List(""); len(got) == 0 {
		t.Fatal("expected at least one topic")
	}
}

func TestService_List_WithQuery(t *testing.T) {
	svc := NewService()

	got := svc.List("jwt")
	if len(got) != 1 || got[0].ID != "1" {
		t.Fatalf("expected only topic 1 for query %q, got %+v", "jwt", got)
	}

	if got := svc.List("no-such-topic-title"); len(got) != 0 {
		t.Fatalf("expected no matches, got %+v", got)
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
