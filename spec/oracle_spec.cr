require "./spec_helper"
require "json"
require "digest/sha256"

describe "official Python reference output" do
  it "matches every sample and key metadata in the official v6 fixture" do
    expected = JSON.parse(File.read(File.join(__DIR__, "fixtures", "official_expected.json"))).as_a
    Pod5::Reader.open(FIXTURE) do |reader|
      expected.each do |row|
        record = reader[row["read_id"].as_s]
        record.sample_count.should eq(row["sample_count"].as_i64)
        record.channel.should eq(row["channel"].as_i)
        record.well.should eq(row["well"].as_i)
        record.read_number.should eq(row["read_number"].as_i)
        record.start_sample.should eq(row["start_sample"].as_i64)
        record.calibration_offset.should eq(row["offset"].as_f.to_f32)
        record.calibration_scale.should eq(row["scale"].as_f.to_f32)
        record.run_info.sample_rate.should eq(row["sample_rate"].as_i)
        # Canonical little-endian representation, including on big-endian hosts.
        digest = Digest::SHA256.new
        buffer = Bytes.new(2)
        record.signal.each do |sample|
          IO::ByteFormat::LittleEndian.encode(sample, buffer)
          digest.update(buffer)
        end
        digest.hexfinal.should eq(row["signal_sha256"].as_s)
      end
    end
  end
end
