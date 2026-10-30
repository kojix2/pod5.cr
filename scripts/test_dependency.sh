#!/bin/sh
# Exercise a fresh path dependency, postinstall, and runtime library discovery.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
trap 'exit 1' HUP INT TERM
unset POD5_NATIVE_PREFIX LIBRARY_PATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH
export POD5_DOWNLOAD_CACHE=${POD5_DOWNLOAD_CACHE:-"$root/vendor/cache"}
dependency="$work/dependency's pod5"
mkdir -p "$dependency" "$work/app/src"
cp -R "$root/src" "$root/ext" "$root/scripts" "$root/shard.yml" "$dependency/"
cat > "$work/app/shard.yml" <<EOF
name: consumer
version: 0.1.0
dependencies:
  pod5:
    path: "$dependency"
targets:
  consumer:
    main: src/consumer.cr
EOF
cat > "$work/app/src/consumer.cr" <<'EOF'
require "pod5"

signal = Slice[100_i16, 102_i16, -101_i16]
encoded = Pod5::VBZ.compress(signal)
raise "VBZ round trip failed" unless Pod5::VBZ.decompress(encoded, signal.size) == signal
run = Pod5::RunInfo.new(acquisition_id: "consumer", sample_rate: 4000_u16)
metadata = Pod5::Metadata.new(run_info: run, channel: 1_u32)
path = "consumer.pod5"
Pod5::Writer.open(path) { |writer| writer.add(metadata, signal) }
Pod5::Reader.open(path) do |reader|
  raise "POD5 round trip failed" unless reader[metadata.read_id].signal == signal
end
puts "Dependency install, build and runtime round trips passed."
EOF
cd "$work/app"
shards install
# Re-running installation must also work when a local dependency is reused.
"$dependency/scripts/install_native.sh"
shards build
./bin/consumer

# A custom installation must be selected at compile time and work at runtime
# without POD5_NATIVE_PREFIX or any library search environment variables.
custom_prefix="$work/native's custom prefix"
mv "$dependency/vendor/pod5" "$custom_prefix"
POD5_NATIVE_PREFIX="$custom_prefix" "$dependency/scripts/install_native.sh"
POD5_NATIVE_PREFIX="$custom_prefix" shards build
rm consumer.pod5
./bin/consumer
