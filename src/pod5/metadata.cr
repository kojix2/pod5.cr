module Pod5
  # Owned metadata: no native pointers and no reused record storage.
  class Metadata
    getter read_id : UUID
    getter run_info : RunInfo
    getter pore_type : String
    getter read_number : UInt32
    getter start_sample : UInt64
    getter median_before : Float32
    getter channel : UInt32
    getter well : UInt8
    getter calibration_offset : Float32
    getter calibration_scale : Float32
    getter end_reason : EndReason
    getter end_reason_forced : Bool
    getter num_minknow_events : UInt64
    getter tracked_scaling_scale : Float32
    getter tracked_scaling_shift : Float32
    getter predicted_scaling_scale : Float32
    getter predicted_scaling_shift : Float32
    getter num_reads_since_mux_change : UInt32
    getter time_since_mux_change : Float32
    getter open_pore_level : Float32
    getter expected_open_pore_level : Float32
    getter selected_read_level : Float32

    def initialize(
      *,
      @read_id : UUID = UUID.random,
      @run_info : RunInfo,
      @pore_type : String = "not_set",
      @read_number : UInt32 = 0_u32,
      @start_sample : UInt64 = 0_u64,
      @median_before : Float32 = Float32::NAN,
      @channel : UInt32,
      @well : UInt8 = 1_u8,
      @calibration_offset : Float32 = 0_f32,
      @calibration_scale : Float32 = 1_f32,
      @end_reason : EndReason = EndReason::Unknown,
      @end_reason_forced : Bool = false,
      @num_minknow_events : UInt64 = 0_u64,
      @tracked_scaling_scale : Float32 = Float32::NAN,
      @tracked_scaling_shift : Float32 = Float32::NAN,
      @predicted_scaling_scale : Float32 = Float32::NAN,
      @predicted_scaling_shift : Float32 = Float32::NAN,
      @num_reads_since_mux_change : UInt32 = 0_u32,
      @time_since_mux_change : Float32 = 0_f32,
      @open_pore_level : Float32 = Float32::NAN,
      @expected_open_pore_level : Float32 = Float32::NAN,
      @selected_read_level : Float32 = Float32::NAN,
    )
      raise ArgumentError.new("channel must be positive") if @channel == 0
      raise ArgumentError.new("well must be positive") if @well == 0
      raise ArgumentError.new("invalid end reason") unless 0 <= @end_reason.value <= 9
      raise ArgumentError.new("calibration_scale must be finite and positive") unless @calibration_scale.finite? && @calibration_scale > 0
      raise ArgumentError.new("calibration_offset must be finite") unless @calibration_offset.finite?
    end
  end

  module ReadAccess
    abstract def metadata : Metadata
    abstract def sample_count : UInt64
    abstract def signal : Slice(Int16)

    delegate read_id, to: metadata
    delegate run_info, to: metadata
    delegate pore_type, to: metadata
    delegate read_number, to: metadata
    delegate start_sample, to: metadata
    delegate median_before, to: metadata
    delegate channel, to: metadata
    delegate well, to: metadata
    delegate calibration_offset, to: metadata
    delegate calibration_scale, to: metadata
    delegate end_reason, to: metadata
    delegate end_reason_forced, to: metadata
    delegate num_minknow_events, to: metadata
    delegate tracked_scaling_scale, to: metadata
    delegate tracked_scaling_shift, to: metadata
    delegate predicted_scaling_scale, to: metadata
    delegate predicted_scaling_shift, to: metadata
    delegate num_reads_since_mux_change, to: metadata
    delegate time_since_mux_change, to: metadata
    delegate open_pore_level, to: metadata
    delegate expected_open_pore_level, to: metadata
    delegate selected_read_level, to: metadata

    def duration : Float64
      sample_count.to_f64 / run_info.sample_rate
    end

    def start_time : Float64
      start_sample.to_f64 / run_info.sample_rate
    end

    def signal_pa : Slice(Float32)
      raw = signal
      Slice(Float32).new(raw.size) { |i| (raw[i].to_f32 + calibration_offset) * calibration_scale }
    end
  end
end
