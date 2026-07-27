---
description: Regenerate the local TLS certificate and update the pin the iOS app uses
allowed-tools: Bash(./scripts/gen-cert.sh:*), Bash(./scripts/spki-pin.sh:*), Read, Edit, Grep
---

The local certificate and the pin hardcoded in the iOS app must always match. Do the full
rotation — regenerating one without the other breaks every request.

1. From `backend/`, run `./scripts/gen-cert.sh`. It writes `certs/server.{crt,key}` and prints
   the new SPKI pin.
2. Take that pin and replace the `.local` pin in
   `ios/Projects/Core/Networking/Sources/Pinning/PinningConfiguration.swift`. Change only the
   `.local` entry — leave `.production` alone.
3. Verify independently: `ios/scripts/spki-pin.sh --cert backend/certs/server.crt` must print
   exactly the value you just pasted.
4. Restart the backend if it was already running — it holds the old certificate in memory.
5. Run `tuist test CoreNetworkingTests` from `ios/` to confirm the pinning tests still pass.

Report the old and new pin values so the change is easy to review.
