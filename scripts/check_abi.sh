#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
prefix=${POD5_NATIVE_PREFIX:-"$root/vendor/pod5"}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT HUP INT TERM
cc -Wno-deprecated-declarations -I "$prefix/include" "$root/scripts/abi.c" -o "$work/native"
"$work/native" > "$work/native.txt"
"$root/scripts/with_native.sh" crystal run "$root/scripts/abi.cr" > "$work/crystal.txt"
diff -u "$work/native.txt" "$work/crystal.txt"
echo 'All C/Crystal struct sizes and offsets agree.'
