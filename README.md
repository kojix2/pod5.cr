# pod5.cr

Crystal >= 1.22 bindings for POD5 metadata, raw/calibrated signals, read selection,
writing and VBZ compression. Uses the native POD5 library; no Python runtime.

## Installation

Requires a C++20 compiler, curl, tar, unzip, patch and SHA256 tools.
The installer supports Linux x86_64/ARM64 and macOS 14+ ARM64. It verifies pinned
downloads and builds the compatibility API for POD5 0.3.49.

```yaml
dependencies:
  pod5:
    github: kojix2/pod5.cr
```

In your application:

```sh
shards install
crystal run main.cr
```

The postinstall hook installs the native library; ordinary builds need no wrapper.
`POD5_NATIVE_PREFIX` selects an absolute prefix for both installation and compilation;
`POD5_DOWNLOAD_CACHE` selects the archive cache. Reinstallation reuses a matching
complete installation and rejects incompatible prefixes. Binaries embed an absolute
rpath: retain that native directory or adjust the deployment rpath. See
[THIRD_PARTY.md](THIRD_PARTY.md) for offline archives, native fixes and licenses.

## Read

```crystal
require "pod5"

Pod5::Reader.open("reads.pod5") do |reader|
  puts reader.size
  reader.each do |read|
    puts "#{read.read_id}: #{read.sample_count} samples"
    adc = read.signal    # Fresh Slice(Int16), loaded on demand.
    pa = read.signal_pa  # Fresh Slice(Float32), in picoamperes.
  end
end
```

`reader[id]?` looks up a UUID; `each_selected(ids)` selects reads in storage order.
Lazy records need an open reader for signal access; `read.materialize` detaches
a copy. Calibration is `(ADC + offset) * scale`.

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

Use a new output path. Closing finalizes the file; exceptions do not roll back
earlier writes. `writer.add(record)` copies a reader record with its metadata.
`Pod5::VBZ.compress(signal)` and `decompress(bytes, sample_count)` handle VBZ.

## Development

From this checkout, also install OpenSSL headers and pkg-config for the tests:

```sh
sh scripts/install_native.sh
sh scripts/download_fixtures.sh
crystal spec
shards build
bin/pod5-info reads.pod5
```

License: MIT for the wrapper; MPL-2.0 for derived ABI declarations/native patches.
See [LICENSE](LICENSE) and [THIRD_PARTY.md](THIRD_PARTY.md).
