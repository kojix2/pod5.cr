#!/bin/sh
# Build the corrected, privately named C API. No Python is needed.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$root/scripts/common.sh"
prefix=${1:-${POD5_NATIVE_PREFIX:-"$root/vendor/pod5"}}
cache=${POD5_DOWNLOAD_CACHE:-"$root/vendor/cache"}
case "$(uname -s)" in
  Linux) output="$prefix/lib/libpod5_cr_compat.so" ;;
  Darwin) output="$prefix/lib/libpod5_cr_compat.dylib" ;;
  *) echo 'This build script supports Linux and macOS only.' >&2; exit 1 ;;
esac
# Verify that a future native header has not silently changed the ABI.
verify_sha256 "$prefix/include/pod5_format/c_api.h" "$POD5_HEADER_SHA256"
source_archive="$cache/pod5-source-$POD5_SOURCE_COMMIT.tar.gz"
fetch_verified \
  "https://codeload.github.com/nanoporetech/pod5-file-format/tar.gz/$POD5_SOURCE_COMMIT" \
  "$POD5_SOURCE_SHA256" "$source_archive" "${POD5_SOURCE_ARCHIVE:-}"
fetch_verified "$ARROW_WHEEL_URL" "$ARROW_WHEEL_SHA256" \
  "$cache/$ARROW_WHEEL" "${POD5_ARROW_ARCHIVE:-}"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 1' HUP INT TERM
source_root="pod5-file-format-$POD5_SOURCE_COMMIT"
tar -xzf "$source_archive" -C "$work" \
  "$source_root/c++/pod5_format/c_api.cpp" \
  "$source_root/third_party/include/gsl" \
  "$source_root/third_party/licenses/gsl-lite.txt" \
  "$source_root/LICENSE.md"
patch --batch --fuzz=0 -d "$work/$source_root" -p1 < "$root/ext/fixes.patch"
unzip -q "$cache/$ARROW_WHEEL" 'pyarrow/include/*' \
  'pyarrow-18.0.0.dist-info/LICENSE*' 'pyarrow-18.0.0.dist-info/NOTICE*' -d "$work"
if [ "$(uname -s)" = Linux ]; then
  "${CXX:-c++}" -std=c++20 -O2 -fPIC -shared -Wno-deprecated-declarations \
    -I "$prefix/include" -I "$work/pyarrow/include" \
    -I "$work/$source_root/third_party/include" -include "$root/ext/symbols.h" \
    "$work/$source_root/c++/pod5_format/c_api.cpp" \
    -L "$prefix/lib" -lpod5_format -Wl,-rpath,'$ORIGIN' -Wl,-z,defs -o "$work/compat.so"
  mv -- "$work/compat.so" "$output"
else
  "${CXX:-c++}" -std=c++20 -O2 -fPIC -dynamiclib -Wno-deprecated-declarations \
    -I "$prefix/include" -I "$work/pyarrow/include" \
    -I "$work/$source_root/third_party/include" -include "$root/ext/symbols.h" \
    "$work/$source_root/c++/pod5_format/c_api.cpp" \
    -L "$prefix/lib" -lpod5_format -Wl,-rpath,@loader_path \
    -Wl,-install_name,@rpath/libpod5_cr_compat.dylib -o "$work/compat.dylib"
  mv -- "$work/compat.dylib" "$output"
fi
# Keep the modified MPL source and build notices alongside installed binaries.
mkdir -p "$prefix/src/pod5-cr" "$prefix/licenses/pod5-cr"
cp -- "$work/$source_root/c++/pod5_format/c_api.cpp" "$root/ext/symbols.h" \
  "$root/ext/fixes.patch" "$prefix/src/pod5-cr/"
cp -- "$work/$source_root/LICENSE.md" "$prefix/licenses/pod5-cr/LICENSE-POD5"
cp -- "$work/$source_root/third_party/licenses/gsl-lite.txt" "$prefix/licenses/pod5-cr/LICENSE-GSL"
cp -- "$work/pyarrow-18.0.0.dist-info/LICENSE.txt" "$prefix/licenses/pod5-cr/LICENSE-ARROW"
cp -- "$work/pyarrow-18.0.0.dist-info/NOTICE.txt" "$prefix/licenses/pod5-cr/NOTICE-ARROW"
printf 'Built %s\n' "$output"
