#!/usr/bin/env bash
set -euo pipefail

# Writes an SPKI pin into the `.local` pin set of PinningConfiguration.swift.
# This is the write half of the rotation that `backend/scripts/gen-cert.sh`
# and `spki-pin.sh` only read: regenerating the certificate without running
# this leaves every request failing with NetworkError.pinningFailure.
#
# The `.production` pin set is never touched. Running twice with the same pin
# changes nothing, so it is safe to call from a script that may re-run.
#
# Usage:
#   set-local-pin.sh <pin>                  write the pin
#   set-local-pin.sh --from-cert <file>     compute the pin from a certificate first
#   set-local-pin.sh --print                print the pin currently in the file

script_dir="$(cd "$(dirname "$0")" && pwd)"
config="$script_dir/../Projects/Core/Networking/Sources/Pinning/PinningConfiguration.swift"

usage() {
  grep '^#' "$0" | tail -n +2 | sed 's/^# \{0,1\}//'
  exit 1
}

# Prints the single pin currently in the `.local` set, or nothing if the file
# no longer has the shape this script expects.
current_pin() {
  awk '
    /case \.local:/      { in_local = 1 }
    /case \.production:/ { in_local = 0 }
    in_local && match($0, /pins: \["[^"]+"\]/) {
      pin = substr($0, RSTART + 8, RLENGTH - 10)
      print pin
      exit
    }
  ' "$config"
}

[[ $# -ge 1 ]] || usage
[[ -f "$config" ]] || { echo "error: not found: $config" >&2; exit 1; }

case "$1" in
  --print)
    current_pin
    exit 0
    ;;
  --from-cert)
    [[ $# -eq 2 ]] || usage
    pin="$("$script_dir/spki-pin.sh" --cert "$2")"
    ;;
  -*)
    usage
    ;;
  *)
    [[ $# -eq 1 ]] || usage
    pin="$1"
    ;;
esac

# A SHA-256 SPKI pin is always 44 base64 characters. Catching a malformed value
# here is much cheaper than debugging a pinning failure inside the app.
if [[ ! "$pin" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
  echo "error: '$pin' is not a base64 SHA-256 pin (44 characters)" >&2
  exit 1
fi

old="$(current_pin)"
if [[ -z "$old" ]]; then
  echo "error: could not find the .local pin set in $config" >&2
  exit 1
fi

if [[ "$old" == "$pin" ]]; then
  echo "Pin already up to date: $pin"
  exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# The range guard keeps the edit inside `case .local:`; `.production` has its
# own pins and must survive untouched.
awk -v pin="$pin" '
  /case \.local:/      { in_local = 1 }
  /case \.production:/ { in_local = 0 }
  in_local && !done && match($0, /pins: \["[^"]+"\]/) {
    printf "%spins: [\"%s\"]%s\n",
      substr($0, 1, RSTART - 1), pin, substr($0, RSTART + RLENGTH)
    done = 1
    next
  }
  { print }
  END { if (!done) exit 1 }
' "$config" > "$tmp"

cat "$tmp" > "$config"

echo "Updated the .local pin in ${config#"$script_dir/../"}"
echo "  old: $old"
echo "  new: $pin"
