#!/usr/bin/env bash
set -euo pipefail

# The full verification loop for the Go side: formatting, static checks, tests.
# The fastlane `backend_check` lane and the CI workflow both call this script,
# so there is one definition of "the backend is fine" instead of three.
#
# The tests are mock-only — nothing here needs a running server or a certificate.

cd "$(dirname "$0")/.."

# `gofmt -l` prints the offending files but still exits 0, so the exit status
# alone would never catch a formatting problem.
unformatted="$(gofmt -l .)"
if [[ -n "$unformatted" ]]; then
  echo "error: these files are not gofmt-formatted:" >&2
  echo "$unformatted" >&2
  echo "Run 'gofmt -w .' in backend/." >&2
  exit 1
fi
echo "gofmt: clean"

go vet ./...
echo "go vet: clean"

go test ./...
