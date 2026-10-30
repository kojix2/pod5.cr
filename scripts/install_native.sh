#!/bin/sh
# Download the official standalone C/C++ library. Python is not used.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/scripts/common.sh"
prefix=${1:-${POD5_NATIVE_PREFIX:-"$root/vendor/pod5"}}
cache=${POD5_DOWNLOAD_CACHE:-"$root/vendor/cache"}
case "$(uname -s):$(uname -m)" in
  Linux:x86_64) platform=linux-x64; checksum=$POD5_LINUX_X64_SHA256; extension=so ;;
  Linux:aarch64|Linux:arm64) platform=linux-arm64; checksum=$POD5_LINUX_ARM64_SHA256; extension=so ;;
  Darwin:arm64) platform=osx-14.0-arm64; checksum=$POD5_MACOS_ARM64_SHA256; extension=dylib ;;
  *) echo 'No pinned binary for this platform; build libpod5_format 0.3.49 from source.' >&2; exit 1 ;;
esac
if [ -e "$prefix" ] || [ -L "$prefix" ]; then
  if [ -f "$prefix/POD5_VERSION" ] && [ "$(cat "$prefix/POD5_VERSION")" = "$POD5_VERSION" ] &&
     [ -f "$prefix/lib/libpod5_format.$extension" ] &&
     [ -f "$prefix/lib/libpod5_cr_compat.$extension" ]; then
    verify_sha256 "$prefix/include/pod5_format/c_api.h" "$POD5_HEADER_SHA256"
    printf 'Using existing libpod5_format %s in %s\n' "$POD5_VERSION" "$prefix"
    exit 0
  fi
  echo "Destination already exists: $prefix (choose a new prefix)." >&2
  exit 1
fi
mkdir -p "$(dirname -- "$prefix")"
work=$(mktemp -d "$(dirname -- "$prefix")/.pod5-install.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
trap 'exit 1' HUP INT TERM
archive="lib_pod5-$POD5_VERSION-$platform.tar.gz"
fetch_verified \
  "https://github.com/nanoporetech/pod5-file-format/releases/download/$POD5_VERSION/$archive" \
  "$checksum" "$cache/$archive" "${POD5_ARCHIVE:-}"
mkdir "$work/package"
tar -xzf "$cache/$archive" -C "$work/package"
printf '%s\n' "$POD5_VERSION" > "$work/package/POD5_VERSION"
"$root/scripts/build_compat.sh" "$work/package"
mv "$work/package" "$prefix"
printf 'Installed libpod5_format %s in %s\n' "$POD5_VERSION" "$prefix"
