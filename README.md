# pod5.cr

Crystal bindings for Oxford Nanopore POD5: read metadata and raw signals,
select reads by UUID, write files, and compress/decompress VBZ signals.
Uses the official native POD5 library; no Python installation is required.

## Setup

Tested with Crystal 1.22.0 and POD5 0.3.49 on Linux x86_64. Requires a C++20
compiler, curl, tar, unzip, patch and sha256sum (or shasum). Tests also need
OpenSSL headers and pkg-config for Crystal's standard SHA256 bindings.

```sh
./scripts/install_native.sh
./scripts/download_fixtures.sh
./scripts/with_native.sh crystal spec
./scripts/with_native.sh shards build
./scripts/with_native.sh ./bin/pod5-info reads.pod5
```

The installer downloads pinned POD5 binaries/source and matching Arrow/gsl-lite
headers, verifies SHA256 checksums, and builds a small corrected C API. Arrow
headers are extracted from a PyArrow wheel using unzip; Python code and wheel
binaries are not used. External sources, headers, libraries, download caches and
binary test fixtures are ignored by Git. Versions and checksums are in
`scripts/common.sh`; provenance and licenses are in [THIRD_PARTY.md](THIRD_PARTY.md).

The downloader recognizes Linux ARM64 and macOS 14+ ARM64 packages, but those
platforms have not been tested. Windows is not supported by the scripts. The
compatibility library depends on POD5's pinned C++ ABI; use version 0.3.49.

For a local dependency in another Crystal project:

```yaml
dependencies:
  pod5:
    path: /absolute/path/to/pod5.cr
```

Run `shards install` and compile through this project's `scripts/with_native.sh`.
It sets linker/runtime search paths. `POD5_NATIVE_PREFIX` overrides the default
`vendor/pod5` installation prefix; `POD5_DOWNLOAD_CACHE` overrides `vendor/cache`.
The prefix must not already exist when installing.

For offline installation, populate the download cache or supply all three
archives explicitly; the same checksum verification applies:

```sh
POD5_ARCHIVE=/path/to/lib_pod5-0.3.49-linux-x64.tar.gz \
POD5_SOURCE_ARCHIVE=/path/to/pod5-source.tar.gz \
POD5_ARROW_ARCHIVE=/path/to/pyarrow-18.0.0-cp312-cp312-manylinux_2_28_x86_64.whl \
  ./scripts/install_native.sh
```

Offline tests also need the two fixture files listed in `THIRD_PARTY.md`.
`download_fixtures.sh` verifies existing fixtures without downloading them again.

## Read

```crystal
require "pod5"

Pod5::Reader.open("reads.pod5") do |reader|
  puts reader.size
  reader.each do |read|
    puts "#{read.read_id}\t#{read.channel}\t#{read.sample_count}"
    adc = read.signal   # Fresh Slice(Int16); loaded only when requested.
    pa = read.signal_pa # Fresh Slice(Float32), in picoamperes.
  end

  # UUID objects and strings are accepted. Results follow storage order.
  reader.each_selected(["0000173c-bf67-44e7-9a9c-1ad0bc728e74"]) do |read|
    detached = read.materialize # Copies signal; remains valid after close.
  end
end
```

`reader[id]?` returns nil for an absent UUID; `reader[id]` raises `KeyError`.
Selection deduplicates requests and raises for missing IDs before yielding;
use `strict: false` to skip them. Malformed UUID strings raise `ArgumentError`.
`read_ids` allocates all IDs; `each` streams metadata without loading signals.

Calibration is `(ADC + calibration_offset) * calibration_scale`. `duration`
and `start_time` are seconds derived from the run's sample rate. `start_sample`
is the acquisition-relative sample index. `signal_into(buffer)` accepts an
exact-sized `Slice(Int16)` for buffer reuse.

## Write

```crystal
require "pod5"

run = Pod5::RunInfo.new(acquisition_id: UUID.random.to_s, sample_rate: 4000_u16)
metadata = Pod5::Metadata.new(run_info: run, channel: 1_u32,
  calibration_offset: 0_f32, calibration_scale: 0.25_f32)

Pod5::Writer.open("new.pod5") do |writer|
  writer.add(metadata, Slice[100_i16, 101_i16, 99_i16])
end
```

`writer.add(record)` copies a reader-backed record with metadata and signal.
`Pod5::Read.new(metadata, signal)` creates a detached copy; `writer.add(reads)`
accepts an `Array(Pod5::Read)` for batch writes. Run and pore dictionaries are
registered automatically; conflicting metadata for an acquisition ID raises.
Empty strings/maps, 32-bit channels and optional/deprecated fields are preserved.

Writer options are `compression` (default `Pod5::Compression::VBZ`, also
`Uncompressed`), `max_signal_chunk_size` (102400), `read_table_batch_size` (1000),
`signal_table_batch_size` (100), and `writer_name` (`"pod5.cr 0.1.0"`).

Existing paths, including dangling symlinks, are refused. Closing finalizes the
file; block forms close on exceptions but do not roll back writes. A failed
native write makes the writer unusable. For atomic replacement, write and
successfully close a temporary file, then rename it. Do not concurrently create
the same output path from different processes.

## Ownership and concurrency

Metadata is owned and remains valid after close. Lazy records retain their
reader, but signal access after explicit close raises `Pod5::ClosedError`.
`signal` allocates on every call; a detached `Read#signal` exposes its owned,
mutable buffer. Run maps are returned as copies. Readers cache one native batch.
Slice/array sizes are limited to Int32 and oversized conversions raise.

Calls and close on each reader/writer are serialized by a mutex; iteration
blocks run outside the lock. Separate readers can run in parallel using
Crystal-managed fibers/execution contexts. Native calls occupy their executing
thread. Do not mutate signals during writes or call `LibPod5.terminate` while
using the wrapper. Prefer block forms; finalizers cannot report close errors.

## VBZ

```crystal
encoded = Pod5::VBZ.compress(Slice[100_i16, 102_i16, 101_i16])
raw = Pod5::VBZ.decompress(encoded, 3)
Pod5::VBZ.decompress_into(encoded, Slice(Int16).new(3))
```

The sample count is supplied separately. Empty signals work; corrupt input or
inconsistent sample counts raise `Pod5::Error`.

## Native compatibility and validation

`ext/fixes.patch` corrects the upstream C API's null 16-bit channel access on
v6 tables and rejection of legal empty run metadata/maps. `ext/symbols.h`
renames the corrected API to `pod5_cr_*`, isolating it from the unmodified
official library. To rebuild: `./scripts/build_compat.sh /path/to/native-prefix`.

CI checks formatting, shell syntax, verified downloads, C/Crystal struct sizes
and offsets (`./scripts/check_abi.sh`), debug/release specs, and the info CLI.
Specs cover official v0/v6 fixtures, v7 round trips, reference signal hashes,
ownership, invalid inputs, VBZ and shared readers/writers across four workers.
The tests use a stored reference and do not invoke Python.

## License

Original wrapper/project code: MIT. Derived ABI declarations and native patch:
MPL-2.0. See [THIRD_PARTY.md](THIRD_PARTY.md) for dependency licenses and source
provenance.
