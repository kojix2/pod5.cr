module Pod5
  # Explicit close is required to finish the POD5 footer. A failed write may
  # leave a partial file; write to a temporary path when atomic output is needed.
  class Writer
    getter path : String
    @handle = Pointer(LibPod5::Writer).null
    @mutex = Mutex.new
    @pores = {} of String => Int16
    @runs = {} of String => Tuple(RunInfo, Int16)
    @failed = false

    def initialize(path : Path | String, *, writer_name : String = "pod5.cr #{VERSION}",
                   compression : Compression = Compression::VBZ,
                   max_signal_chunk_size : UInt32 = 102400_u32,
                   signal_table_batch_size : Int32 = 100,
                   read_table_batch_size : Int32 = 1000)
      @path = path.to_s
      Pod5.c_string(@path, "path")
      Pod5.c_string(writer_name, "writer_name")
      raise ArgumentError.new("output already exists: #{@path}") if File.exists?(@path) || File.symlink?(@path)
      raise ArgumentError.new("invalid compression") unless 0 <= compression.value <= 2
      raise ArgumentError.new("chunk size must be positive") if max_signal_chunk_size == 0
      raise ArgumentError.new("batch sizes must be positive") if signal_table_batch_size <= 0 || read_table_batch_size <= 0
      Pod5.init
      options = LibPod5::Pod5WriterOptions.new(
        max_signal_chunk_size: max_signal_chunk_size,
        signal_compression_type: compression.value,
        signal_table_batch_size: signal_table_batch_size.to_u64,
        read_table_batch_size: read_table_batch_size.to_u64)
      @handle = Pod5.check_pointer(LibPod5.create_file(@path, writer_name, pointerof(options)), "create #{@path}")
    end

    def self.open(path : Path | String, **options, &)
      writer = new(path, **options)
      begin
        yield writer
      ensure
        writer.close
      end
    end

    def close : Nil
      @mutex.synchronize do
        handle = @handle
        @handle = Pointer(LibPod5::Writer).null
        @pores.clear
        @runs.clear
        Pod5.check(LibPod5.close_and_free_writer(handle), "close writer") unless handle.null?
      end
    end

    def closed? : Bool
      @mutex.synchronize { @handle.null? }
    end

    def finalize
      LibPod5.close_and_free_writer(@handle) unless @handle.null?
    end

    # Borrowed only for the synchronous native call. The caller must not
    # mutate the signal until this method returns.
    private class WriteView
      include ReadAccess
      getter metadata : Metadata
      getter signal : Slice(Int16)

      def initialize(@metadata, @signal)
      end

      def sample_count : UInt64
        @signal.size.to_u64
      end
    end

    def add(metadata : Metadata, signal : Slice(Int16)) : Nil
      write_batch([WriteView.new(metadata, signal)])
    end

    def add(record : Record) : Nil
      add(record.metadata, record.signal)
    end

    def add(read : Read) : Nil
      add([read])
    end

    # Efficient column-oriented native call for a group of detached reads.
    # Duplicate read IDs are not tracked globally (bounded memory).
    def add(reads : Array(Read)) : Nil
      write_batch(reads)
    end

    private def write_batch(reads) : Nil
      @mutex.synchronize do
        ensure_open
        return if reads.empty?
        reads.each do |read|
          Pod5.c_string(read.pore_type, "pore_type")
          validate_run(read.run_info)
        end
        begin
          write_reads(reads)
        rescue ex : Error
          @failed = true
          raise ex
        end
      end
    end

    private def ensure_open : Nil
      raise ClosedError.new("POD5 writer is closed") if @handle.null?
      raise Error.new(4, "POD5 writer cannot be reused after a native write failure") if @failed
    end

    private def pore_index(pore : String) : Int16
      @pores[pore] ||= begin
        raise ArgumentError.new("too many distinct pore types") if @pores.size >= Int16::MAX
        index = 0_i16
        Pod5.check(LibPod5.add_pore(pointerof(index), @handle, pore), "add pore")
        index
      end
    end

    private def run_index(run : RunInfo) : Int16
      if existing = @runs[run.acquisition_id]?
        raise ArgumentError.new("conflicting metadata for acquisition_id #{run.acquisition_id}") unless existing[0] == run
        return existing[1]
      end
      raise ArgumentError.new("too many distinct runs") if @runs.size >= Int16::MAX
      index = add_run(run)
      @runs[run.acquisition_id] = {run, index}
      index
    end

    private def write_reads(reads) : Nil
      read_id = reads.map { |read| read.read_id.bytes }
      run_info_id = reads.map { |read| run_index(read.run_info) }
      pore_type = reads.map { |read| pore_index(read.pore_type) }
      read_number = reads.map { |read| read.read_number }
      start_sample = reads.map { |read| read.start_sample }
      median_before = reads.map { |read| read.median_before }
      channel = reads.map { |read| read.channel }
      well = reads.map { |read| read.well }
      calibration_offset = reads.map { |read| read.calibration_offset }
      calibration_scale = reads.map { |read| read.calibration_scale }
      end_reason = reads.map { |read| read.end_reason.value }
      end_reason_forced = reads.map { |read| read.end_reason_forced ? 1_u8 : 0_u8 }
      num_minknow_events = reads.map { |read| read.num_minknow_events }
      tracked_scaling_scale = reads.map { |read| read.tracked_scaling_scale }
      tracked_scaling_shift = reads.map { |read| read.tracked_scaling_shift }
      predicted_scaling_scale = reads.map { |read| read.predicted_scaling_scale }
      predicted_scaling_shift = reads.map { |read| read.predicted_scaling_shift }
      num_reads_since_mux_change = reads.map { |read| read.num_reads_since_mux_change }
      time_since_mux_change = reads.map { |read| read.time_since_mux_change }
      open_pore_level = reads.map { |read| read.open_pore_level }
      expected_open_pore_level = reads.map { |read| read.expected_open_pore_level }
      selected_read_level = reads.map { |read| read.selected_read_level }
      row_data = LibPod5::ReadBatchRowInfoArrayV7.new(
        read_id: read_id.to_unsafe,
        run_info_id: run_info_id.to_unsafe,
        pore_type: pore_type.to_unsafe,
        read_number: read_number.to_unsafe,
        start_sample: start_sample.to_unsafe,
        median_before: median_before.to_unsafe,
        channel: channel.to_unsafe,
        well: well.to_unsafe,
        calibration_offset: calibration_offset.to_unsafe,
        calibration_scale: calibration_scale.to_unsafe,
        end_reason: end_reason.to_unsafe,
        end_reason_forced: end_reason_forced.to_unsafe,
        num_minknow_events: num_minknow_events.to_unsafe,
        tracked_scaling_scale: tracked_scaling_scale.to_unsafe,
        tracked_scaling_shift: tracked_scaling_shift.to_unsafe,
        predicted_scaling_scale: predicted_scaling_scale.to_unsafe,
        predicted_scaling_shift: predicted_scaling_shift.to_unsafe,
        num_reads_since_mux_change: num_reads_since_mux_change.to_unsafe,
        time_since_mux_change: time_since_mux_change.to_unsafe,
        open_pore_level: open_pore_level.to_unsafe,
        expected_open_pore_level: expected_open_pore_level.to_unsafe,
        selected_read_level: selected_read_level.to_unsafe,
      )
      dummy = 0_i16
      signals = reads.map { |read| read.signal.empty? ? pointerof(dummy) : read.signal.to_unsafe }
      sizes = reads.map { |read| read.sample_count.to_u32 }
      Pod5.check(LibPod5.add_reads_data(@handle, reads.size.to_u32, API_VERSION,
        pointerof(row_data), signals, sizes), "write reads")
    end

    private def validate_run(run : RunInfo) : Nil
      Pod5.c_string(run.acquisition_id, "acquisition_id")
      Pod5.c_string(run.experiment_name, "experiment_name")
      Pod5.c_string(run.flow_cell_id, "flow_cell_id")
      Pod5.c_string(run.flow_cell_product_code, "flow_cell_product_code")
      Pod5.c_string(run.protocol_name, "protocol_name")
      Pod5.c_string(run.protocol_run_id, "protocol_run_id")
      Pod5.c_string(run.sample_id, "sample_id")
      Pod5.c_string(run.sequencing_kit, "sequencing_kit")
      Pod5.c_string(run.sequencer_position, "sequencer_position")
      Pod5.c_string(run.sequencer_position_type, "sequencer_position_type")
      Pod5.c_string(run.software, "software")
      Pod5.c_string(run.system_name, "system_name")
      Pod5.c_string(run.system_type, "system_type")
      [run.context_tags, run.tracking_id].each do |map|
        map.each do |key, value|
          Pod5.c_string(key, "map key")
          Pod5.c_string(value, "map value")
        end
      end
    end

    private def add_run(run : RunInfo) : Int16
      context = run.context_tags
      tracking = run.tracking_id
      context_keys = context.keys.map(&.to_unsafe)
      context_values = context.values.map(&.to_unsafe)
      tracking_keys = tracking.keys.map(&.to_unsafe)
      tracking_values = tracking.values.map(&.to_unsafe)
      index = 0_i16
      Pod5.check(LibPod5.add_run_info(
        pointerof(index), @handle,
        run.acquisition_id, run.acquisition_start_time_ms, run.adc_max, run.adc_min,
        context.size, context_keys, context_values,
        run.experiment_name, run.flow_cell_id, run.flow_cell_product_code,
        run.protocol_name, run.protocol_run_id, run.protocol_start_time_ms,
        run.sample_id, run.sample_rate, run.sequencing_kit, run.sequencer_position,
        run.sequencer_position_type, run.software, run.system_name, run.system_type,
        tracking.size, tracking_keys, tracking_values), "add run info")
      index
    end
  end
end
