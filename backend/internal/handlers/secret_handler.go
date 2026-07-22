package handlers

import "net/http"

// secretHandler returns the value the iOS app is meant to store in
// the Keychain behind biometric access control. It must be wrapped
// with the auth middleware.
func secretHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{
			"secret": "correct-horse-battery-staple",
		})
	}
}
