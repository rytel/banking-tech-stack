---
description: Start the backend, run the end-to-end iOS UI tests, then stop the backend
allowed-tools: Bash(bundle exec fastlane:*), Bash(lsof:*), Read
---

Run a real end-to-end check: `AppUITests` needs a live backend, unlike the mock-only unit tests.
The `e2e` lane does the whole sequence, from the repository root:

```
bundle exec fastlane ios e2e
```

The lane handles the parts that are easy to get wrong on your own:

- generates `backend/certs/server.{crt,key}` if they are missing (they are never committed);
- points the `.local` SPKI pin at the key the running server actually serves, so the tests cannot
  fail with `NetworkError.pinningFailure` for the wrong reason;
- reuses a backend that is already listening on `https://localhost:8443` instead of starting a
  second one, and only stops the server it started itself;
- puts the committed pin back afterwards, so the working tree stays clean whether the tests passed
  or failed.

Report pass/fail with the actual failure output if any. Then confirm with `lsof -ti :8443` that no
backend the lane started is still running.

If the lane reports that it generated a new certificate, tell the user: their local setup now has a
certificate that no longer matches the committed pin, and `/rotate-pin` is the way to make that
permanent.
