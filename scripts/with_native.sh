#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
prefix=${POD5_NATIVE_PREFIX:-"$root/vendor/pod5"}
if [ ! -f "$prefix/lib/libpod5_cr_compat.so" ] && [ ! -f "$prefix/lib/libpod5_cr_compat.dylib" ]; then
  echo 'Native library missing. Run scripts/install_native.sh or set POD5_NATIVE_PREFIX.' >&2
  exit 1
fi
[ "$#" -gt 0 ] || { echo 'Usage: scripts/with_native.sh COMMAND [ARG ...]' >&2; exit 1; }
export LIBRARY_PATH="$prefix/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export LD_LIBRARY_PATH="$prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export DYLD_LIBRARY_PATH="$prefix/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
exec "$@"
