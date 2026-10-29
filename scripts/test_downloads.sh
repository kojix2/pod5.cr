#!/bin/sh
# Offline regression checks for verified downloads and failure cleanup.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/scripts/common.sh"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 1' HUP INT TERM
empty_sha=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
url=https://example.invalid/archive
: > "$work/empty"
printf 'corrupt' > "$work/corrupt"

# Cached/offline inputs must never contact the network.
curl() { echo 'Unexpected network request' >&2; return 1; }
fetch_verified "$url" "$empty_sha" "$work/cache" "$work/empty"
fetch_verified "$url" "$empty_sha" "$work/cache"
if fetch_verified "$url" "$empty_sha" "$work/cache" "$work/corrupt" 2> "$work/error"; then
  echo 'Accepted a corrupt local archive' >&2; exit 1
fi
verify_sha256 "$work/cache" "$empty_sha"
if fetch_verified "$url" "$empty_sha" "$work/corrupt" 2> "$work/error"; then
  echo 'Accepted a corrupt cached archive' >&2; exit 1
fi

# Simulate a transport failure after writing part of the response.
curl() {
  for argument do output=$argument; done
  printf 'partial' > "$output"
  return 22
}
if fetch_verified "$url" "$empty_sha" "$work/failed" 2> "$work/error"; then
  echo 'Accepted a failed download' >&2; exit 1
fi
[ ! -e "$work/failed" ]
for leftover in "$work"/cache.* "$work"/failed.*; do
  [ ! -e "$leftover" ] || { echo 'Left a partial download behind' >&2; exit 1; }
done
echo 'Verified downloads: offline/cache reuse, corrupt inputs and failure cleanup passed.'
