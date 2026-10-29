# Third-party components

| Component | Provenance | License / included notice |
| --- | --- | --- |
| POD5 C ABI declarations and C API patch | nanoporetech/pod5-file-format, commit `3f3f240a91c02ce9499e291991c02402ef925529`, release 0.3.49 | MPL-2.0; `ext/LICENSE-POD5` |
| Downloaded POD5 C API and test fixtures | Same pinned commit | MPL-2.0; source license retained during installation |
| Downloaded Apache Arrow headers | `pyarrow-18.0.0-cp312-cp312-manylinux_2_28_x86_64.whl`, `pyarrow/include` | Apache-2.0 and bundled third-party licenses; wheel `LICENSE.txt`, `NOTICE.txt` and header notices |
| Downloaded gsl-lite headers | Pinned POD5 source, `third_party/include/gsl` | MIT; `third_party/licenses/gsl-lite.txt` |

The official POD5 binary archive is downloaded on installation, not redistributed
in this source archive. It carries its own dependency licenses in `vendor/pod5/licenses`.
The binary bundles Arrow 18.0.0; the downloaded Arrow headers deliberately match it.
External source files, headers, archives, binaries and test fixture payloads
are not committed. Their URLs, versions and SHA256 checksums are pinned in
`scripts/common.sh` and `scripts/download_fixtures.sh`.

The build preserves the patched C API source, symbol definitions and patch in
`vendor/pod5/src/pod5-cr`, and its dependency notices in
`vendor/pod5/licenses/pod5-cr` (under your prefix if overridden). Keep these
sources and notices available when redistributing the compatibility binary.
The MIT license on new Crystal code does not replace third-party licenses.

## Test data

Run `./scripts/download_fixtures.sh` before the specs. The binaries come from
the pinned POD5 commit's `test_data/` directory via GitHub LFS media URLs, and
are verified against these SHA256 checksums:

| Local file | Upstream file | SHA256 |
| --- | --- | --- |
| `spec/fixtures/official_v0.pod5` | `multi_fast5_zip_v0.pod5` | `9eb656f0061f1621b205b4c5f4d9694b03cad4480c66e2a2d8ea4423f53ea243` |
| `spec/fixtures/official_v6.pod5` | `multi_fast5_zip_v6.pod5` | `94b7c0e854f67137100048b55b28d1544f01d226ddf3c3bb908c726725163900` |

Both contain the same ten reads in different schema versions and use the
upstream MPL-2.0 license (`ext/LICENSE-POD5`). `official_expected.json` was
generated using Python pod5 0.3.49 and PyArrow 22.0.0; signal hashes represent
signed 16-bit little-endian samples. Python is not needed to run the specs.

Upstream: https://github.com/nanoporetech/pod5-file-format

Arrow: https://github.com/apache/arrow/tree/apache-arrow-18.0.0
