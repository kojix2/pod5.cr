require "./spec_helper"

describe Pod5 do
  it "reads official v6 data without decompressing during metadata iteration" do
    Pod5::Reader.open(FIXTURE) do |reader|
      reader.size.should eq(10)
      reader.read_ids.size.should eq(10)
      reader.file_identifier.should be_a(UUID)
      reader.file_version.should_not be_empty
      records = [] of Pod5::Record
      reader.each { |r| records << r }
      records.map(&.read_id).should eq(reader.read_ids)
      records.map(&.object_id).uniq.size.should eq(10)
      reader.run_infos.should_not be_empty
      records.each do |r|
        r.signal.size.to_u64.should eq(r.sample_count)
        r.duration.should eq(r.sample_count.to_f64 / r.run_info.sample_rate)
        r.signal_pa[0].should eq((r.signal[0].to_f32 + r.calibration_offset) * r.calibration_scale)
      end
    end
  end

  it "reads and migrates the official v0 fixture" do
    Pod5::Reader.open(File.join(__DIR__, "fixtures", "official_v0.pod5")) do |reader|
      reader.size.should eq(10)
      reader.each { |r| r.signal.size.to_u64.should eq(r.sample_count) }
    end
  end

  it "supports read selection, absent IDs, duplicates and independent signals" do
    Pod5::Reader.open(FIXTURE, disable_mmap: true) do |reader|
      ids = reader.read_ids
      result = [] of UUID
      reader.each_selected([ids[9], ids[0], ids[0]]) { |r| result << r.read_id }
      result.should eq([ids[0], ids[9]])
      reader[ids[0].to_s].read_id.should eq(ids[0])
      missing = UUID.random
      reader[missing]?.should be_nil
      expect_raises(KeyError) { reader[missing] }
      yielded = false
      expect_raises(KeyError) { reader.each_selected([ids[0], missing]) { yielded = true } }
      yielded.should be_false
      reader.each_selected([missing], strict: false) { fail "unexpected row" }
      reader.each_selected([] of UUID) { fail "unexpected row" }
      record = reader[ids[0]]
      a = record.signal
      b = record.signal
      a[0] = a[0] &+ 1_i16
      a[0].should_not eq(b[0])
      buffer = Slice(Int16).new(record.sample_count.to_i)
      record.signal_into(buffer).should eq(b)
      expect_raises(ArgumentError) { record.signal_into(Slice(Int16).new(1)) }
    end
  end

  it "keeps metadata and detached signals valid after close, rejects lazy access" do
    reader = Pod5::Reader.new(FIXTURE)
    record = reader[reader.read_ids.first]
    read = record.materialize
    before = read.signal.dup
    reader.close
    reader.close
    reader.closed?.should be_true
    record.read_id.should eq(read.read_id)
    read.signal.should eq(before)
    expect_raises(Pod5::ClosedError) { record.signal }
    expect_raises(Pod5::ClosedError) { reader.size }
    expect_raises(Pod5::ClosedError) { reader.each { } }
    expect_raises(Pod5::ClosedError) { reader.each_selected([] of UUID) { } }
  end

  [Pod5::Compression::VBZ, Pod5::Compression::Uncompressed].each do |compression|
    it "round trips all metadata, 32-bit channels and chunked signals with #{compression}" do
      with_path do |path|
        run = test_run
        reads = Array.new(9) { |i| test_read(run, 257 + i, i.to_u32) }
        Pod5::Writer.open(path, compression: compression, max_signal_chunk_size: 31_u32,
          read_table_batch_size: 2, signal_table_batch_size: 3) do |writer|
          writer.add(reads)
        end
        Pod5::Reader.open(path) do |reader|
          reader.size.should eq(9)
          reader.batch_count.should eq(5)
          reader.run_infos.size.should eq(1)
          reader.run_infos.first.should eq(run)
          records = [] of Pod5::Record
          reader.each { |r| records << r }
          records.each_with_index do |r, i|
            original = reads[i]
            r.read_id.should eq(original.read_id)
            r.signal.should eq(original.signal)
            r.channel.should eq(123456_u32)
            r.start_sample.should eq(1000)
            r.calibration_offset.should eq(-10_f32)
            r.calibration_scale.should eq(0.25_f32)
            r.end_reason.should eq(Pod5::EndReason::ApiRequest)
            r.end_reason_forced.should be_true
            r.num_minknow_events.should eq(56)
            r.tracked_scaling_scale.should eq(1.1_f32)
            r.tracked_scaling_shift.should eq(2.2_f32)
            r.predicted_scaling_scale.should eq(3.3_f32)
            r.predicted_scaling_shift.should eq(4.4_f32)
            r.num_reads_since_mux_change.should eq(7)
            r.time_since_mux_change.should eq(8.5_f32)
            r.open_pore_level.should eq(100_f32)
            r.expected_open_pore_level.should eq(101_f32)
            r.selected_read_level.should eq(102_f32)
          end
          records.first.signal.should eq(reads.first.signal)
          records.last.signal.should eq(reads.last.signal)
        end
      end
    end
  end

  it "handles an empty file and empty signal" do
    with_path do |path|
      Pod5::Writer.open(path) { }
      Pod5::Reader.open(path) do |reader|
        reader.size.should eq(0)
        reader.read_ids.should be_empty
        reader.each { fail "unexpected read" }
        reader[UUID.random]?.should be_nil
        expect_raises(KeyError) { reader.each_selected([UUID.random]) { } }
      end
    end
    with_path do |path|
      read = test_read(count: 0)
      Pod5::Writer.open(path) { |writer| writer.add(read) }
      Pod5::Reader.open(path) { |reader| reader[read.read_id].signal.should be_empty }
    end
  end

  it "copies reads between files and accepts metadata plus a signal" do
    with_path do |path|
      Pod5::Reader.open(FIXTURE) do |source|
        Pod5::Writer.open(path) do |writer|
          source.each { |r| writer.add(r) }
          read = test_read
          writer.add(read.metadata, read.signal)
        end
        Pod5::Reader.open(path) do |copy|
          copy.size.should eq(11)
          source.each { |r| copy[r.read_id].signal.should eq(r.signal) }
        end
      end
    end
  end

  it "preserves run identity across batches with different dictionaries" do
    with_path do |path|
      a = test_read(test_run("a"), number: 1_u32)
      b = test_read(test_run("b"), number: 2_u32)
      Pod5::Writer.open(path, read_table_batch_size: 1) { |w| w.add([a, b, a]) }
      Pod5::Reader.open(path) do |reader|
        runs = [] of String
        reader.each { |r| runs << r.run_info.acquisition_id }
        runs.should eq(["a", "b", "a"])
      end
    end
  end

  it "refuses conflicting run metadata and protects input maps" do
    run = test_run
    tags = run.context_tags
    tags["unicode"] = "changed"
    run.context_tags["unicode"].should eq("実験")
    with_path do |path|
      Pod5::Writer.open(path) do |w|
        w.add(test_read(run))
        expect_raises(ArgumentError, /conflicting/) { w.add(test_read(test_run(sample_rate: 5000_u16))) }
      end
    end
  end

  it "closes on block exceptions and does not overwrite an existing file" do
    reader_ref = nil.as(Pod5::Reader?)
    expect_raises(Exception, "body") do
      Pod5::Reader.open(FIXTURE) do |reader|
        reader_ref = reader
        raise "body"
      end
    end
    reader_ref.not_nil!.closed?.should be_true
    with_path do |path|
      writer = Pod5::Writer.new(path)
      writer.close
      writer.close
      expect_raises(Pod5::ClosedError) { writer.add([] of Pod5::Read) }
      before = File.read(path)
      expect_raises(ArgumentError) { Pod5::Writer.new(path) }
      File.read(path).should eq(before)
    end
  end

  it "rejects missing, invalid and truncated files and NUL paths" do
    with_path do |path|
      expect_raises(Pod5::Error) { Pod5::Reader.new(path) }
      File.write(path, "not pod5")
      expect_raises(Pod5::Error) { Pod5::Reader.new(path) }
      File.write(path, File.read(FIXTURE)[0, 512])
      expect_raises(Pod5::Error) { Pod5::Reader.new(path) }
    end
    expect_raises(ArgumentError) { Pod5::Reader.new("bad\0path") }
    expect_raises(ArgumentError) { Pod5::Metadata.new(run_info: test_run, channel: 0_u32) }
    expect_raises(ArgumentError) { test_run(sample_rate: 0_u16) }
  end

  it "serializes a reader across a four-worker execution context" do
    reader = Pod5::Reader.new(FIXTURE)
    ids = reader.read_ids
    context = Fiber::ExecutionContext::Parallel.new("pod5-reader-test", 4)
    errors = Channel(Exception?).new(4)
    4.times do |index|
      context.spawn do
        begin
          5.times do
            record = reader[ids[index]]
            record.signal.size.to_u64.should eq(record.sample_count)
          end
          errors.send(nil)
        rescue ex
          errors.send(ex)
        end
      end
    end
    4.times { errors.receive.should be_nil }
    reader.close
  end
end

describe Pod5::VBZ do
  it "round trips empty, extreme and long signals" do
    signals = [Slice(Int16).empty, Slice[-32768_i16, 32767_i16, 0_i16, -1_i16],
               Slice(Int16).new(200_001) { |i| (i % 65536 - 32768).to_i16 }]
    signals.each do |signal|
      compressed = Pod5::VBZ.compress(signal)
      Pod5::VBZ.decompress(compressed, signal.size).should eq(signal)
      output = Slice(Int16).new(signal.size)
      Pod5::VBZ.decompress_into(compressed, output).should eq(signal)
    end
  end

  it "rejects corrupt compressed bytes and incorrect sample counts" do
    expect_raises(Pod5::Error) { Pod5::VBZ.decompress(Bytes[1, 2, 3], 10) }
    encoded = Pod5::VBZ.compress(Slice[1_i16, 2_i16])
    expect_raises(Pod5::Error) { Pod5::VBZ.decompress(encoded, 1) }
    expect_raises(ArgumentError) { Pod5::VBZ.decompress(encoded, -1) }
  end
end
