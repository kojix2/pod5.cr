# Pinned build inputs. Source this file; it is not a standalone command.
POD5_VERSION=0.3.49
POD5_SOURCE_COMMIT=3f3f240a91c02ce9499e291991c02402ef925529
POD5_SOURCE_SHA256=b72fd23bb8580de23298538c54f8ed58466cc8f928ef240e787701d7716adef0
POD5_HEADER_SHA256=0b3e6fb52407bea72a347586499643f93e79bac984e74da60f8998f08d7dccba
POD5_LINUX_X64_SHA256=7d9eda9d2e37a08be1b4763f310ab5bf9dc3ab7d4c0bd49b6010602d74aab759
POD5_LINUX_ARM64_SHA256=c895a963c5b58e92c805cf8183e7c4584dda6705c11ea555f8dd8635a847f25c
POD5_MACOS_ARM64_SHA256=2b17ab8f0cfe5226a9c84cfbfe01ea64a52cd6e240cdf21940c20bc9eddf42c2
# Extract headers and notices only; no Python code or shared libraries are used.
ARROW_WHEEL=pyarrow-18.0.0-cp312-cp312-manylinux_2_28_x86_64.whl
ARROW_WHEEL_URL=https://files.pythonhosted.org/packages/8d/1f/9bb3b3a644892d631dbbe99053cdb5295092d2696b4bcd3d21f29624c689/pyarrow-18.0.0-cp312-cp312-manylinux_2_28_x86_64.whl
ARROW_WHEEL_SHA256=a71ab0589a63a3e987beb2bc172e05f000a5c5be2636b4b263c44034e215b5d7

# Verified downloads shared by installation and test fixture setup.
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

verify_sha256() {
  if [ "$(sha256 "$1")" != "$2" ]; then
    printf 'SHA256 verification failed: %s\n' "$1" >&2
    return 1
  fi
}

# Optional fourth argument supplies an offline archive. Every cached/local file
# is checked before use; incomplete downloads never replace the destination.
fetch_verified() (
  set -eu
  url=$1 checksum=$2 destination=$3 local_file=${4:-}
  if [ -z "$local_file" ] && [ -f "$destination" ]; then
    verify_sha256 "$destination" "$checksum" || exit 1
    exit 0
  fi
  mkdir -p "$(dirname -- "$destination")" || exit 1
  temporary=$(mktemp "${destination}.XXXXXX") || exit 1
  trap 'rm -f -- "$temporary"' EXIT
  trap 'exit 1' HUP INT TERM
  if [ -n "$local_file" ]; then
    cp -- "$local_file" "$temporary" || exit 1
  else
    curl --fail --location --retry 3 --connect-timeout 20 \
      --proto '=https' --proto-redir '=https' --tlsv1.2 \
      "$url" --output "$temporary" || exit 1
  fi
  verify_sha256 "$temporary" "$checksum" || exit 1
  mv -- "$temporary" "$destination" || exit 1
)
