require "spec"
require "file_utils"
require "../src/pod5"

FIXTURE = File.join(__DIR__, "fixtures", "official_v6.pod5")
unless File.file?(FIXTURE) && File.file?(File.join(__DIR__, "fixtures", "official_v0.pod5"))
  abort "Test fixtures missing. Run ./scripts/download_fixtures.sh before crystal spec."
end

def with_path(&)
  directory = File.join(Dir.tempdir, "pod5-cr-#{UUID.random}")
  Dir.mkdir(directory)
  begin
    yield File.join(directory, "test.pod5")
  ensure
    FileUtils.rm_rf(directory)
  end
end

def test_run(id = "test-acquisition", sample_rate = 4000_u16)
  Pod5::RunInfo.new(acquisition_id: id, sample_rate: sample_rate,
    acquisition_start_time_ms: 1_700_000_000_123_i64,
    protocol_start_time_ms: 1_699_999_990_456_i64,
    context_tags: {"sample_frequency" => "4000", "unicode" => "実験"},
    tracking_id: {"device_id" => "P2"}, sample_id: "sample", sequencing_kit: "SQK-LSK114")
end

def test_read(run = test_run, count = 257, number = 42_u32, channel = 123456_u32)
  metadata = Pod5::Metadata.new(run_info: run, channel: channel, read_number: number,
    start_sample: 1000_u64, median_before: 72_f32,
    calibration_offset: -10_f32, calibration_scale: 0.25_f32,
    end_reason: Pod5::EndReason::ApiRequest, end_reason_forced: true,
    pore_type: "R10.4.1", num_minknow_events: 56_u64,
    tracked_scaling_scale: 1.1_f32, tracked_scaling_shift: 2.2_f32,
    predicted_scaling_scale: 3.3_f32, predicted_scaling_shift: 4.4_f32,
    num_reads_since_mux_change: 7_u32, time_since_mux_change: 8.5_f32,
    open_pore_level: 100_f32, expected_open_pore_level: 101_f32,
    selected_read_level: 102_f32)
  signal = Slice(Int16).new(count) { |i| ((i % 200) - 100).to_i16 }
  Pod5::Read.new(metadata, signal)
end
