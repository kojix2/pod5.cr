module Pod5
  class RunInfo
    getter acquisition_id : String
    getter acquisition_start_time_ms : Int64
    getter adc_max : Int16
    getter adc_min : Int16
    getter experiment_name : String
    getter flow_cell_id : String
    getter flow_cell_product_code : String
    getter protocol_name : String
    getter protocol_run_id : String
    getter protocol_start_time_ms : Int64
    getter sample_id : String
    getter sample_rate : UInt16
    getter sequencing_kit : String
    getter sequencer_position : String
    getter sequencer_position_type : String
    getter software : String
    getter system_name : String
    getter system_type : String

    def initialize(
      *,
      @acquisition_id : String,
      @acquisition_start_time_ms : Int64 = 0_i64,
      @adc_max : Int16 = 4095_i16,
      @adc_min : Int16 = -4096_i16,
      @context_tags : Hash(String, String) = {} of String => String,
      @experiment_name : String = "",
      @flow_cell_id : String = "",
      @flow_cell_product_code : String = "",
      @protocol_name : String = "",
      @protocol_run_id : String = "",
      @protocol_start_time_ms : Int64 = 0_i64,
      @sample_id : String = "",
      @sample_rate : UInt16,
      @sequencing_kit : String = "",
      @sequencer_position : String = "",
      @sequencer_position_type : String = "",
      @software : String = "",
      @system_name : String = "",
      @system_type : String = "",
      @tracking_id : Hash(String, String) = {} of String => String,
    )
      raise ArgumentError.new("sample_rate must be positive") if @sample_rate == 0
      raise ArgumentError.new("adc_min must be less than adc_max") unless @adc_min < @adc_max
      @context_tags = @context_tags.dup
      @tracking_id = @tracking_id.dup
    end

    def context_tags : Hash(String, String)
      @context_tags.dup
    end

    def tracking_id : Hash(String, String)
      @tracking_id.dup
    end

    protected def self.from_native(data : LibPod5::RunInfoDictData) : self
      new(
        acquisition_id: Pod5.copy_string(data.acquisition_id),
        acquisition_start_time_ms: data.acquisition_start_time_ms,
        adc_max: data.adc_max,
        adc_min: data.adc_min,
        context_tags: Pod5.copy_map(data.context_tags),
        experiment_name: Pod5.copy_string(data.experiment_name),
        flow_cell_id: Pod5.copy_string(data.flow_cell_id),
        flow_cell_product_code: Pod5.copy_string(data.flow_cell_product_code),
        protocol_name: Pod5.copy_string(data.protocol_name),
        protocol_run_id: Pod5.copy_string(data.protocol_run_id),
        protocol_start_time_ms: data.protocol_start_time_ms,
        sample_id: Pod5.copy_string(data.sample_id),
        sample_rate: data.sample_rate,
        sequencing_kit: Pod5.copy_string(data.sequencing_kit),
        sequencer_position: Pod5.copy_string(data.sequencer_position),
        sequencer_position_type: Pod5.copy_string(data.sequencer_position_type),
        software: Pod5.copy_string(data.software),
        system_name: Pod5.copy_string(data.system_name),
        system_type: Pod5.copy_string(data.system_type),
        tracking_id: Pod5.copy_map(data.tracking_id),
      )
    end

    def_equals_and_hash @acquisition_id, @acquisition_start_time_ms, @adc_max, @adc_min, @experiment_name, @flow_cell_id, @flow_cell_product_code, @protocol_name, @protocol_run_id, @protocol_start_time_ms, @sample_id, @sample_rate, @sequencing_kit, @sequencer_position, @sequencer_position_type, @software, @system_name, @system_type, @context_tags, @tracking_id
  end
end
