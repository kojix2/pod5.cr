module Pod5
  # One native batch is cached per reader. Calls and close are serialized.
  # User blocks run outside the lock and may use another reader or a writer.
  class Reader
    getter path : String
    @handle = Pointer(LibPod5::Reader).null
    @batch = Pointer(LibPod5::Batch).null
    @batch_index = -1
    @mutex = Mutex.new
    @runs = {} of String => RunInfo
    @batch_runs = {} of Int16 => RunInfo
    @pores = {} of Int16 => String
    @end_reasons = {} of Int16 => EndReason

    def initialize(path : Path | String, *, disable_mmap : Bool = false)
      @path = path.to_s
      Pod5.c_string(@path, "path")
      Pod5.init
      options = LibPod5::Pod5ReaderOptions.new(force_disable_file_mapping: disable_mmap ? 1_u8 : 0_u8)
      @handle = Pod5.check_pointer(LibPod5.open_file_options(@path, pointerof(options)), "open #{@path}")
    end

    def self.open(path : Path | String, *, disable_mmap : Bool = false, &)
      reader = new(path, disable_mmap: disable_mmap)
      begin
        yield reader
      ensure
        reader.close
      end
    end

    def close : Nil
      @mutex.synchronize do
        batch, handle = @batch, @handle
        @batch = Pointer(LibPod5::Batch).null
        @handle = Pointer(LibPod5::Reader).null
        @batch_index = -1
        @batch_runs.clear
        @runs.clear
        @pores.clear
        @end_reasons.clear
        begin
          Pod5.check(LibPod5.free_read_batch(batch), "free batch") unless batch.null?
        ensure
          Pod5.check(LibPod5.close_and_free_reader(handle), "close reader") unless handle.null?
        end
      end
    end

    def closed? : Bool
      @mutex.synchronize { @handle.null? }
    end

    def finalize
      # No other reachable object can be calling this reader at finalization.
      LibPod5.free_read_batch(@batch) unless @batch.null?
      LibPod5.close_and_free_reader(@handle) unless @handle.null?
    end

    def size : UInt64
      @mutex.synchronize do
        ensure_open
        count = LibC::SizeT.new(0)
        Pod5.check(LibPod5.get_read_count(@handle, pointerof(count)), "read count")
        count.to_u64
      end
    end

    def batch_count : Int32
      @mutex.synchronize do
        ensure_open
        count = LibC::SizeT.new(0)
        Pod5.check(LibPod5.get_read_batch_count(pointerof(count), @handle), "batch count")
        count.to_i
      end
    end

    def file_identifier : UUID
      @mutex.synchronize do
        ensure_open
        info = LibPod5::FileInfo.new
        Pod5.check(LibPod5.get_file_info(@handle, pointerof(info)), "file info")
        UUID.new(info.file_identifier)
      end
    end

    # The producer's POD5 library version, not the read-table schema version.
    def file_version : String
      @mutex.synchronize do
        ensure_open
        info = LibPod5::FileInfo.new
        Pod5.check(LibPod5.get_file_info(@handle, pointerof(info)), "file info")
        v = info.version
        "#{v.major}.#{v.minor}.#{v.revision}"
      end
    end

    def read_ids : Array(UUID)
      @mutex.synchronize do
        ensure_open
        count = LibC::SizeT.new(0)
        Pod5.check(LibPod5.get_read_count(@handle, pointerof(count)), "read count")
        return [] of UUID if count == 0
        ids = Slice(LibPod5::ReadId).new(count.to_i) { StaticArray(UInt8, 16).new(0_u8) }
        Pod5.check(LibPod5.get_read_ids(@handle, count, ids), "read IDs")
        Array(UUID).new(ids.size) { |i| UUID.new(ids[i]) }
      end
    end

    def run_infos : Array(RunInfo)
      @mutex.synchronize do
        ensure_open
        count = 0_u16
        Pod5.check(LibPod5.get_file_run_info_count(@handle, pointerof(count)), "run count")
        Array(RunInfo).new(count.to_i) do |i|
          pointer = Pointer(LibPod5::RunInfoDictData).null
          Pod5.check(LibPod5.get_file_run_info(@handle, i.to_u16, pointerof(pointer)), "run info")
          copy_run(pointer)
        end
      end
    end

    # Streaming metadata iteration. No Enumerable or implicit collection.
    def each(& : Record ->) : Nil
      batch_count.times do |batch_index|
        rows = @mutex.synchronize do
          batch = load_batch(batch_index)
          count = LibC::SizeT.new(0)
          Pod5.check(LibPod5.get_read_batch_row_count(pointerof(count), batch), "batch row count")
          count.to_i
        end
        rows.times { |row| yield record_at(batch_index, row) }
      end
    end

    # Deduplicates requests, then yields in storage order. With strict=true,
    # missing IDs raise before any record is yielded.
    def each_selected(ids : Enumerable(UUID | String), *, strict : Bool = true, & : Record ->) : Nil
      requested = ids.map { |id| id.is_a?(UUID) ? id : UUID.new(id) }.uniq.to_a
      counts, rows = plan(requested, strict)
      offset = 0
      counts.each_with_index do |count, batch_index|
        count.times do
          yield record_at(batch_index, rows[offset].to_i)
          offset += 1
        end
      end
    end

    def []?(id : UUID | String) : Record?
      each_selected([id], strict: false) { |record| return record }
      nil
    end

    def [](id : UUID | String) : Record
      self[id]? || raise KeyError.new("read ID not found: #{id}")
    end

    protected def read_signal(batch_index : Int32, row : Int32, buffer : Slice(Int16)) : Nil
      @mutex.synchronize do
        batch = load_batch(batch_index)
        unless buffer.empty?
          Pod5.check(LibPod5.get_read_complete_signal(@handle, batch, row, buffer.size, buffer), "read signal")
        end
      end
    end

    private def ensure_open : Nil
      raise ClosedError.new("POD5 reader is closed") if @handle.null?
    end

    private def load_batch(index : Int32) : Pointer(LibPod5::Batch)
      ensure_open
      return @batch if @batch_index == index
      batch = Pointer(LibPod5::Batch).null
      Pod5.check(LibPod5.get_read_batch(pointerof(batch), @handle, index), "load batch #{index}")
      LibPod5.free_read_batch(@batch) unless @batch.null?
      @batch = batch
      @batch_index = index
      @batch_runs.clear
      @pores.clear
      @end_reasons.clear
      batch
    end

    private def copy_run(pointer : Pointer(LibPod5::RunInfoDictData)) : RunInfo
      begin
        id = Pod5.copy_string(pointer.value.acquisition_id)
        @runs[id] ||= RunInfo.from_native(pointer.value)
      ensure
        LibPod5.free_run_info(pointer)
      end
    end

    private def run_info(batch : Pointer(LibPod5::Batch), index : Int16) : RunInfo
      @batch_runs[index] ||= begin
        pointer = Pointer(LibPod5::RunInfoDictData).null
        Pod5.check(LibPod5.get_run_info(batch, index, pointerof(pointer)), "read run info")
        copy_run(pointer)
      end
    end

    private def pore_type(batch : Pointer(LibPod5::Batch), index : Int16) : String
      @pores[index] ||= begin
        buffer = Bytes.new(128)
        length = LibC::SizeT.new(buffer.size)
        code = LibPod5.get_pore_type(batch, index, buffer, pointerof(length))
        if code == 12
          buffer = Bytes.new(length.to_i)
          code = LibPod5.get_pore_type(batch, index, buffer, pointerof(length))
        end
        Pod5.check(code, "read pore type")
        String.new(buffer.to_unsafe)
      end
    end

    private def end_reason(batch : Pointer(LibPod5::Batch), index : Int16) : EndReason
      @end_reasons[index] ||= begin
        buffer = Bytes.new(128)
        length = LibC::SizeT.new(buffer.size)
        value = 0
        Pod5.check(LibPod5.get_end_reason(batch, index, pointerof(value), buffer, pointerof(length)), "read end reason")
        EndReason.from_value(value)
      end
    end

    private def plan(ids : Array(UUID), strict : Bool)
      @mutex.synchronize do
        ensure_open
        count = LibC::SizeT.new(0)
        Pod5.check(LibPod5.get_read_batch_count(pointerof(count), @handle), "batch count")
        counts = Array(UInt32).new(count.to_i, 0_u32)
        rows = Array(UInt32).new(ids.size, 0_u32)
        return {counts, rows} if ids.empty?
        packed = ids.map(&.bytes)
        found = LibC::SizeT.new(0)
        # Empty POD5 files have no batches; do not pass a null output to C.
        unless counts.empty?
          Pod5.check(LibPod5.plan_traversal(@handle, packed.to_unsafe.as(UInt8*), ids.size,
            counts, rows, pointerof(found)), "plan read selection")
        end
        if strict && found != ids.size
          raise KeyError.new("#{ids.size - found.to_i} requested read ID(s) not found")
        end
        {counts, rows}
      end
    end

    private def record_at(batch_index : Int32, row : Int32) : Record
      @mutex.synchronize do
        batch = load_batch(batch_index)
        data = LibPod5::ReadBatchRowInfoV7.new
        table_version = 0_u16
        Pod5.check(LibPod5.get_read_batch_row_info_data(batch, row, API_VERSION,
          pointerof(data), pointerof(table_version)), "read metadata")
        metadata = metadata_from(data, batch)
        Record.new(self, batch_index, row, metadata, data.num_samples, table_version)
      end
    end

    private def metadata_from(data : LibPod5::ReadBatchRowInfoV7, batch : Pointer(LibPod5::Batch)) : Metadata
      Metadata.new(
        read_id: UUID.new(data.read_id),
        run_info: run_info(batch, data.run_info),
        pore_type: pore_type(batch, data.pore_type),
        read_number: data.read_number,
        start_sample: data.start_sample,
        median_before: data.median_before,
        channel: data.channel,
        well: data.well,
        calibration_offset: data.calibration_offset,
        calibration_scale: data.calibration_scale,
        end_reason: end_reason(batch, data.end_reason),
        end_reason_forced: data.end_reason_forced != 0,
        num_minknow_events: data.num_minknow_events,
        tracked_scaling_scale: data.tracked_scaling_scale,
        tracked_scaling_shift: data.tracked_scaling_shift,
        predicted_scaling_scale: data.predicted_scaling_scale,
        predicted_scaling_shift: data.predicted_scaling_shift,
        num_reads_since_mux_change: data.num_reads_since_mux_change,
        time_since_mux_change: data.time_since_mux_change,
        open_pore_level: data.open_pore_level,
        expected_open_pore_level: data.expected_open_pore_level,
        selected_read_level: data.selected_read_level,
      )
    end
  end
end
