require "./spec_helper"

describe "ownership and native compatibility edge cases" do
  it "refuses a dangling symlink without creating its target" do
    with_path do |path|
      target = "#{path}.target"
      File.symlink(target, path)
      expect_raises(ArgumentError, /output already exists/) { Pod5::Writer.new(path) }
      File.symlink?(path).should be_true
      File.exists?(target).should be_false
    end
  end

  it "round trips empty maps, empty strings and Unicode without substitution" do
    with_path do |path|
      run = Pod5::RunInfo.new(acquisition_id: "empty-fields", sample_rate: 4000_u16,
        context_tags: {"" => "", "日本語" => "測定"}, tracking_id: {} of String => String)
      metadata = Pod5::Metadata.new(run_info: run, channel: 1_u32)
      Pod5::Writer.open(path) { |w| w.add(metadata, Slice[1_i16]) }
      Pod5::Reader.open(path) do |r|
        actual = r[metadata.read_id].run_info
        actual.should eq(run)
        actual.experiment_name.should eq("")
        actual.tracking_id.should be_empty
      end
    end
    with_path do |path|
      run = Pod5::RunInfo.new(acquisition_id: "empty-maps", sample_rate: 4000_u16)
      Pod5::Writer.open(path) { |w| w.add(Pod5::Metadata.new(run_info: run, channel: 1_u32), Slice[2_i16]) }
      Pod5::Reader.open(path) { |r| r.run_infos.first.should eq(run) }
    end
  end

  it "resizes native string buffers for long pore names" do
    with_path do |path|
      pore = "pore-" + "x" * 1024
      metadata = Pod5::Metadata.new(run_info: test_run, channel: 1_u32, pore_type: pore)
      Pod5::Writer.open(path) { |w| w.add(metadata, Slice[100_i16]) }
      Pod5::Reader.open(path) { |r| r[metadata.read_id].pore_type.should eq(pore) }
    end
  end

  it "retains native handles through GC and keeps owned input signals independent" do
    with_path do |path|
      source = Slice[10_i16, 11_i16]
      read = Pod5::Read.new(Pod5::Metadata.new(run_info: test_run, channel: 1_u32), source)
      source[0] = 999_i16
      read.signal[0].should eq(10_i16)
      Pod5::Writer.open(path, read_table_batch_size: 1) do |w|
        4.times do
          GC.collect
          w.add(read)
        end
      end
      records = [] of Pod5::Record
      reader = Pod5::Reader.new(path)
      reader.each { |r| records << r }
      GC.collect
      records.each { |r| r.signal.should eq(Slice[10_i16, 11_i16]) }
      reader.close
    end
  end

  it "rejects NUL metadata before writing, leaving the writer usable" do
    with_path do |path|
      Pod5::Writer.open(path) do |w|
        bad = Pod5::Metadata.new(run_info: test_run, channel: 1_u32, pore_type: "a\0b")
        expect_raises(ArgumentError) { w.add(bad, Slice[1_i16]) }
        w.add(test_read)
      end
      Pod5::Reader.open(path) { |r| r.size.should eq(1) }
    end
  end
end

describe "parallel writer" do
  it "serializes native batch additions and dictionary registration" do
    with_path do |path|
      context = Fiber::ExecutionContext::Parallel.new("pod5-writer-test", 4)
      errors = Channel(Exception?).new(4)
      run = test_run
      reads = Array.new(20) { |i| test_read(run, 100 + i, i.to_u32) }
      Pod5::Writer.open(path, read_table_batch_size: 3) do |writer|
        4.times do |index|
          context.spawn do
            begin
              writer.add(reads[index * 5, 5])
              errors.send(nil)
            rescue ex
              errors.send(ex)
            end
          end
        end
        4.times { errors.receive.should be_nil }
      end
      Pod5::Reader.open(path) do |reader|
        reader.size.should eq(20)
        reads.each { |r| reader[r.read_id].signal.should eq(r.signal) }
      end
    end
  end
end
