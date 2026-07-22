package topics

import "banking-tech-stack/backend/internal/models"

// seed is the static list of topics served by the API. Content is
// irrelevant for this training project — what matters is exercising
// JSON decoding on the iOS side.
var seed = []models.Topic{
	{ID: "1", Title: "JWT signing: ES256 vs HS256", Description: "Why a client cannot verify an HS256 token without exposing the shared secret."},
	{ID: "2", Title: "Refresh token single-flight", Description: "Serializing concurrent token refreshes with an actor so that N parallel requests trigger only one refresh call."},
	{ID: "3", Title: "Tuist modularization", Description: "Splitting an app into feature and core modules, and the dependency rule between them."},
	{ID: "4", Title: "Certificate pinning", Description: "Pinning the SPKI hash instead of the leaf certificate, and how to rotate pins."},
	{ID: "5", Title: "Keychain accessibility", Description: "Choosing kSecAttrAccessibleWhenUnlockedThisDeviceOnly and what it means for backups."},
}
