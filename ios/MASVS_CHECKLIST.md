# MASVS checklist — STORAGE and AUTH

Based on a review of the code in `ios/Projects`. Target: MASVS L2.
Legend: ✅ done, ⚠️ partial / needs verification, ❌ missing.

## MASVS-STORAGE

### STORAGE-1 — secure storage of sensitive data

| # | Requirement | Status | Evidence in code |
|---|---|---|---|
| 1 | Refresh token stored in Keychain, not in files/UserDefaults | ✅ | `ios/Projects/Core/SecureStorage/Sources/Auth/RefreshTokenStorage.swift` |
| 2 | Correct Keychain accessibility class (`ThisDeviceOnly`) | ✅ | `.whenUnlockedThisDeviceOnly` in `ios/Projects/Core/SecureStorage/Sources/Keychain/KeychainAccessibility.swift:12` |
| 3 | Access token is short-lived, kept in memory only | ✅ | `ios/Projects/Core/SecureStorage/Sources/Auth/AccessTokenStore.swift` — an `actor`, no persistence |
| 4 | Sensitive secrets protected by biometry (`biometryCurrentSet` ACL) | ✅ | `SecretStore.swift`, `SecureEnclaveSigner.swift` — **but not wired into any screen**, so effectively unused |
| 5 | Cryptographic key generated in the Secure Enclave, non-exportable | ✅ | `SecureEnclave.P256.Signing.PrivateKey` |
| 6 | No hardcoded secrets/API keys in the repo | ⚠️ | not thoroughly checked — worth running `grep -ri "secret\|apikey\|password ="` across the whole repo |
| 7 | No unencrypted sensitive data in cache/tmp/CoreData files | ⚠️ | no such mechanisms exist yet — the app has no persistent business data beyond tokens, so this is formally "not applicable", but worth recording as a deliberate decision |

### STORAGE-2 — preventing leakage of sensitive data

| # | Requirement | Status | Notes |
|---|---|---|---|
| 1 | No logging of sensitive data (passwords, tokens) | ✅ | The only logging is the RASP status in `CompositionRoot.swift:24` — contains no secrets |
| 2 | Password field uses `SecureField` | ✅ | `AuthView.swift:21` |
| 3 | Keyboard cache/autocorrect disabled on the password field | ⚠️ | `autocorrectionDisabled()` is only applied to the **username** field (`AuthView.swift:18`); `SecureField` disables autocorrect by default, but this should be verified explicitly |
| 4 | Content hidden in the App Switcher (privacy overlay) | ❌ | no `scenePhase`/blur handling when the app moves to the background |
| 5 | Screenshot / screen-recording protection for sensitive views | ❌ | not implemented |
| 6 | HTTP response caching disabled for sensitive data | ⚠️ | `HTTPClient` does not set `requestCachePolicy`/`URLCache.shared = nil` |
| 7 | Backup exclusion for sensitive data | ✅ (debatable) | The code comment assumes `ThisDeviceOnly` excludes the item from encrypted backups entirely — technically Apple does not exclude such items from an encrypted backup, it only blocks decrypting them after a restore onto a different device. The intended security effect (no session hijack on a new device) is achieved, but this should be clarified in NOTES |

## MASVS-AUTH

| # | Requirement | Status | Evidence / notes |
|---|---|---|---|
| 1 (AUTH-1) | Login is performed server-side, the app does not validate on its own | ✅ | `AuthRepository.swift` calls the backend |
| 2 (AUTH-1) | Session token (refresh) is random, rotated, single-use | ✅ | `TokenRefreshCoordinator` assumes refresh-token rotation on the backend side |
| 3 (AUTH-1) | Logout invalidates the local session (clears tokens) | ⚠️ | `clearSession()` exists in `AuthSessionStore.swift:37`, but **is never called** — there is no logout button/screen in the UI |
| 4 (AUTH-1) | Automatic access-token refresh on 401 (without losing the session) | ❌ | `CompositionRoot` explicitly states: "Wired and ready, but not yet consumed" — `TokenRefreshCoordinator` exists but is not hooked into `HTTPClient`, so a 401 does not trigger a refresh |
| 5 (AUTH-2) | Secure storage of the second-factor material (biometry) | ✅ | `SecretStore` / `SecureEnclaveSigner` with `biometryCurrentSet` |
| 6 (AUTH-2) | Second factor actually used in login/re-auth | ❌ | These components are "complete and tested, but not wired into any view model" (quote from `ios/CLAUDE.md`) |
| 7 (AUTH-3) | Step-up auth (extra verification) for sensitive operations (e.g. a transfer) | ❌ | The app has no transactional operations yet — to be implemented once such a feature exists |
| 8 (AUTH-4) | Uses standard platform mechanisms (Keychain, LocalAuthentication, CryptoKit) instead of custom crypto | ✅ | All code is built on `Security`/`LocalAuthentication`/`CryptoKit`, no custom crypto |
| 9 (AUTH-4) | Brute-force protection (rate limiting) | ⚠️ | This is normally a backend concern — needs verification in the `backend/` repo, not in iOS |
| 10 (AUTH-4) | User password is not stored on the device | ✅ | `password` in `AuthViewModel` is a plain `String` used only to send the request, never persisted |

## Summary — can this be called "L2" yet?

The foundation for L2 is solid (Secure Enclave, biometry, SPKI pinning, RASP as defense-in-depth,
actor-based token handling), but **it's not yet accurate to say "built for MASVS L2"**, because
some elements that L2 specifically requires as defense-in-depth on top of L1 are still missing:

1. Auto-refresh on 401 does not work end-to-end (AUTH-1) — the mechanism exists but isn't wired up.
2. No logout button/flow calling `clearSession()` (AUTH-1).
3. Biometry (`SecretStore`/`SecureEnclaveSigner`) is unused in any real flow (AUTH-2).
4. No App Switcher / screenshot protection (STORAGE-2) — a standard L2 requirement for banking apps.
5. HTTP caching behavior and a full audit for hardcoded secrets still need to be verified.
