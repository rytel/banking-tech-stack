package auth

import "testing"

func TestService_LoginThenRefresh(t *testing.T) {
	svc, err := NewService()
	if err != nil {
		t.Fatalf("NewService: %v", err)
	}

	access, refresh, expiresIn, err := svc.Login(demoUsername, demoPassword)
	if err != nil {
		t.Fatalf("Login: %v", err)
	}
	if access == "" || refresh == "" || expiresIn <= 0 {
		t.Fatalf("expected non-empty tokens and positive TTL, got access=%q refresh=%q expiresIn=%d", access, refresh, expiresIn)
	}

	newAccess, newRefresh, _, err := svc.Refresh(refresh)
	if err != nil {
		t.Fatalf("Refresh: %v", err)
	}
	if newAccess == access {
		t.Fatal("expected a fresh access token on refresh")
	}
	if newRefresh == refresh {
		t.Fatal("expected the refresh token to rotate")
	}

	// The old refresh token must not be usable a second time.
	if _, _, _, err := svc.Refresh(refresh); err == nil {
		t.Fatal("expected the consumed refresh token to be rejected")
	}
}

func TestService_LoginRejectsWrongPassword(t *testing.T) {
	svc, err := NewService()
	if err != nil {
		t.Fatalf("NewService: %v", err)
	}

	if _, _, _, err := svc.Login(demoUsername, "wrong-password"); err == nil {
		t.Fatal("expected login with wrong password to fail")
	}
}
