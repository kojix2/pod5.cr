#!/bin/sh
# Fetch official binary test data without adding it to the repository.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/scripts/common.sh"
base="https://media.githubusercontent.com/media/nanoporetech/pod5-file-format/$POD5_SOURCE_COMMIT/test_data"
fetch_verified "$base/multi_fast5_zip_v0.pod5" \
  9eb656f0061f1621b205b4c5f4d9694b03cad4480c66e2a2d8ea4423f53ea243 \
  "$root/spec/fixtures/official_v0.pod5"
fetch_verified "$base/multi_fast5_zip_v6.pod5" \
  94b7c0e854f67137100048b55b28d1544f01d226ddf3c3bb908c726725163900 \
  "$root/spec/fixtures/official_v6.pod5"
echo 'Official test fixtures verified.'
