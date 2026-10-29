# C ABI from Oxford Nanopore POD5 0.3.49 (MPL-2.0). See THIRD_PARTY.md.
# The high-level wrapper uses API struct version 7.
@[Link("pod5_cr_compat")]
lib LibPod5
  alias ReadId = UInt8[16]
  type Reader = Void
  type Writer = Void
  type Batch = Void

  struct Version
    major : UInt16
    minor : UInt16
    revision : UInt16
  end

  struct ReadBatchRowInfoV3
    read_id : ReadId
    read_number : UInt32
    start_sample : UInt64
    median_before : Float32
    channel : UInt16
    well : UInt8
    pore_type : Int16
    calibration_offset : Float32
    calibration_scale : Float32
    end_reason : Int16
    end_reason_forced : UInt8
    run_info : Int16
    num_minknow_events : UInt64
    tracked_scaling_scale : Float32
    tracked_scaling_shift : Float32
    predicted_scaling_scale : Float32
    predicted_scaling_shift : Float32
    num_reads_since_mux_change : UInt32
    time_since_mux_change : Float32
    signal_row_count : Int64
    num_samples : UInt64
  end

  struct ReadBatchRowInfoV4
    read_id : ReadId
    read_number : UInt32
    start_sample : UInt64
    median_before : Float32
    channel : UInt16
    well : UInt8
    pore_type : Int16
    calibration_offset : Float32
    calibration_scale : Float32
    end_reason : Int16
    end_reason_forced : UInt8
    run_info : Int16
    num_minknow_events : UInt64
    tracked_scaling_scale : Float32
    tracked_scaling_shift : Float32
    predicted_scaling_scale : Float32
    predicted_scaling_shift : Float32
    num_reads_since_mux_change : UInt32
    time_since_mux_change : Float32
    signal_row_count : Int64
    num_samples : UInt64
    open_pore_level : Float32
  end

  struct ReadBatchRowInfoV5
    read_id : ReadId
    read_number : UInt32
    start_sample : UInt64
    median_before : Float32
    channel : UInt16
    well : UInt8
    pore_type : Int16
    calibration_offset : Float32
    calibration_scale : Float32
    end_reason : Int16
    end_reason_forced : UInt8
    run_info : Int16
    num_minknow_events : UInt64
    tracked_scaling_scale : Float32
    tracked_scaling_shift : Float32
    predicted_scaling_scale : Float32
    predicted_scaling_shift : Float32
    num_reads_since_mux_change : UInt32
    time_since_mux_change : Float32
    signal_row_count : Int64
    num_samples : UInt64
    open_pore_level : Float32
    expected_open_pore_level : Float32
    selected_read_level : Float32
  end

  struct ReadBatchRowInfoV6
    read_id : ReadId
    read_number : UInt32
    start_sample : UInt64
    median_before : Float32
    channel : UInt32
    well : UInt8
    pore_type : Int16
    calibration_offset : Float32
    calibration_scale : Float32
    end_reason : Int16
    end_reason_forced : UInt8
    run_info : Int16
    num_minknow_events : UInt64
    tracked_scaling_scale : Float32
    tracked_scaling_shift : Float32
    predicted_scaling_scale : Float32
    predicted_scaling_shift : Float32
    num_reads_since_mux_change : UInt32
    time_since_mux_change : Float32
    signal_row_count : Int64
    num_samples : UInt64
    open_pore_level : Float32
    expected_open_pore_level : Float32
    selected_read_level : Float32
  end

  struct ReadBatchRowInfoArrayV3
    read_id : ReadId*
    read_number : UInt32*
    start_sample : UInt64*
    median_before : Float32*
    channel : UInt16*
    well : UInt8*
    pore_type : Int16*
    calibration_offset : Float32*
    calibration_scale : Float32*
    end_reason : Int32*
    end_reason_forced : UInt8*
    run_info_id : Int16*
    num_minknow_events : UInt64*
    tracked_scaling_scale : Float32*
    tracked_scaling_shift : Float32*
    predicted_scaling_scale : Float32*
    predicted_scaling_shift : Float32*
    num_reads_since_mux_change : UInt32*
    time_since_mux_change : Float32*
  end

  struct ReadBatchRowInfoArrayV4
    read_id : ReadId*
    read_number : UInt32*
    start_sample : UInt64*
    median_before : Float32*
    channel : UInt16*
    well : UInt8*
    pore_type : Int16*
    calibration_offset : Float32*
    calibration_scale : Float32*
    end_reason : Int32*
    end_reason_forced : UInt8*
    run_info_id : Int16*
    num_minknow_events : UInt64*
    tracked_scaling_scale : Float32*
    tracked_scaling_shift : Float32*
    predicted_scaling_scale : Float32*
    predicted_scaling_shift : Float32*
    num_reads_since_mux_change : UInt32*
    time_since_mux_change : Float32*
    open_pore_level : Float32*
  end

  struct ReadBatchRowInfoArrayV5
    read_id : ReadId*
    read_number : UInt32*
    start_sample : UInt64*
    median_before : Float32*
    channel : UInt16*
    well : UInt8*
    pore_type : Int16*
    calibration_offset : Float32*
    calibration_scale : Float32*
    end_reason : Int32*
    end_reason_forced : UInt8*
    run_info_id : Int16*
    num_minknow_events : UInt64*
    tracked_scaling_scale : Float32*
    tracked_scaling_shift : Float32*
    predicted_scaling_scale : Float32*
    predicted_scaling_shift : Float32*
    num_reads_since_mux_change : UInt32*
    time_since_mux_change : Float32*
    open_pore_level : Float32*
    expected_open_pore_level : Float32*
    selected_read_level : Float32*
  end

  struct ReadBatchRowInfoArrayV6
    read_id : ReadId*
    read_number : UInt32*
    start_sample : UInt64*
    median_before : Float32*
    channel : UInt32*
    well : UInt8*
    pore_type : Int16*
    calibration_offset : Float32*
    calibration_scale : Float32*
    end_reason : Int32*
    end_reason_forced : UInt8*
    run_info_id : Int16*
    num_minknow_events : UInt64*
    tracked_scaling_scale : Float32*
    tracked_scaling_shift : Float32*
    predicted_scaling_scale : Float32*
    predicted_scaling_shift : Float32*
    num_reads_since_mux_change : UInt32*
    time_since_mux_change : Float32*
    open_pore_level : Float32*
    expected_open_pore_level : Float32*
    selected_read_level : Float32*
  end

  struct Pod5ReaderOptions
    force_disable_file_mapping : UInt8
  end

  struct FileInfo
    file_identifier : ReadId
    version : Version
  end

  struct EmbeddedFileData
    file_name : UInt8*
    offset : LibC::SizeT
    length : LibC::SizeT
  end

  struct CalibrationExtraData
    digitisation : UInt16
    range : Float32
  end

  struct KeyValueData
    size : LibC::SizeT
    keys : UInt8**
    values : UInt8**
  end

  struct RunInfoDictData
    acquisition_id : UInt8*
    acquisition_start_time_ms : Int64
    adc_max : Int16
    adc_min : Int16
    context_tags : KeyValueData
    experiment_name : UInt8*
    flow_cell_id : UInt8*
    flow_cell_product_code : UInt8*
    protocol_name : UInt8*
    protocol_run_id : UInt8*
    protocol_start_time_ms : Int64
    sample_id : UInt8*
    sample_rate : UInt16
    sequencing_kit : UInt8*
    sequencer_position : UInt8*
    sequencer_position_type : UInt8*
    software : UInt8*
    system_name : UInt8*
    system_type : UInt8*
    tracking_id : KeyValueData
  end

  struct SignalRowInfo
    batch_index : LibC::SizeT
    batch_row_index : LibC::SizeT
    stored_sample_count : UInt32
    stored_byte_count : LibC::SizeT
  end

  struct Pod5WriterOptions
    max_signal_chunk_size : UInt32
    signal_compression_type : Int8
    signal_table_batch_size : LibC::SizeT
    read_table_batch_size : LibC::SizeT
  end

  alias ReadBatchRowInfoV7 = ReadBatchRowInfoV6
  alias ReadBatchRowInfoArrayV7 = ReadBatchRowInfoArrayV6
  fun get_error_no = pod5_cr_get_error_no : Int32
  fun get_error_string = pod5_cr_get_error_string : UInt8*
  fun init = pod5_cr_init : Int32
  fun terminate = pod5_cr_terminate : Int32
  fun open_file = pod5_cr_open_file(filename : UInt8*) : Reader*
  fun open_file_options = pod5_cr_open_file_options(filename : UInt8*, options : Pod5ReaderOptions*) : Reader*
  fun close_and_free_reader = pod5_cr_close_and_free_reader(file : Reader*) : Int32
  fun get_file_info = pod5_cr_get_file_info(file : Reader*, file_info : FileInfo*) : Int32
  fun get_file_read_table_location = pod5_cr_get_file_read_table_location(file : Reader*, file_data : EmbeddedFileData*) : Int32
  fun get_file_signal_table_location = pod5_cr_get_file_signal_table_location(file : Reader*, file_data : EmbeddedFileData*) : Int32
  fun get_file_run_info_table_location = pod5_cr_get_file_run_info_table_location(file : Reader*, file_data : EmbeddedFileData*) : Int32
  fun get_read_count = pod5_cr_get_read_count(reader : Reader*, count : LibC::SizeT*) : Int32
  fun get_read_ids = pod5_cr_get_read_ids(reader : Reader*, count : LibC::SizeT, read_ids : ReadId*) : Int32
  fun plan_traversal = pod5_cr_plan_traversal(file : Reader*, read_id_array : UInt8*, read_id_count : LibC::SizeT, batch_counts : UInt32*, batch_rows : UInt32*, find_success_count : LibC::SizeT*) : Int32
  fun get_read_batch_count = pod5_cr_get_read_batch_count(count : LibC::SizeT*, reader : Reader*) : Int32
  fun get_read_batch = pod5_cr_get_read_batch(batch : Batch**, reader : Reader*, index : LibC::SizeT) : Int32
  fun free_read_batch = pod5_cr_free_read_batch(batch : Batch*) : Int32
  fun get_read_batch_row_count = pod5_cr_get_read_batch_row_count(count : LibC::SizeT*, batch : Batch*) : Int32
  fun get_read_batch_row_info_data = pod5_cr_get_read_batch_row_info_data(batch : Batch*, row : LibC::SizeT, struct_version : UInt16, row_data : Void*, read_table_version : UInt16*) : Int32
  fun get_signal_row_indices = pod5_cr_get_signal_row_indices(batch : Batch*, row : LibC::SizeT, signal_row_indices_count : Int64, signal_row_indices : UInt64*) : Int32
  fun get_calibration_extra_info = pod5_cr_get_calibration_extra_info(batch : Batch*, row : LibC::SizeT, calibration_extra_data : CalibrationExtraData*) : Int32
  fun get_run_info = pod5_cr_get_run_info(batch : Batch*, run_info : Int16, run_info_data : RunInfoDictData**) : Int32
  fun get_file_run_info = pod5_cr_get_file_run_info(file : Reader*, run_info_index : UInt16, run_info_data : RunInfoDictData**) : Int32
  fun free_run_info = pod5_cr_free_run_info(run_info_data : RunInfoDictData*) : Int32
  fun release_run_info = pod5_cr_release_run_info(run_info_data : RunInfoDictData*) : Int32
  fun get_file_run_info_count = pod5_cr_get_file_run_info_count(file : Reader*, run_info_count : UInt16*) : Int32
  fun get_end_reason = pod5_cr_get_end_reason(batch : Batch*, end_reason : Int16, end_reason_value : Int32*, end_reason_string_value : UInt8*, end_reason_string_value_size : LibC::SizeT*) : Int32
  fun get_pore_type = pod5_cr_get_pore_type(batch : Batch*, pore_type : Int16, pore_type_string_value : UInt8*, pore_type_string_value_size : LibC::SizeT*) : Int32
  fun get_signal_row_info = pod5_cr_get_signal_row_info(reader : Reader*, signal_rows_count : LibC::SizeT, signal_rows : UInt64*, signal_row_info : SignalRowInfo**) : Int32
  fun free_signal_row_info = pod5_cr_free_signal_row_info(signal_rows_count : LibC::SizeT, signal_row_info : SignalRowInfo**) : Int32
  fun get_signal = pod5_cr_get_signal(reader : Reader*, row_info : SignalRowInfo*, sample_count : LibC::SizeT, sample_data : Int16*) : Int32
  fun get_read_complete_sample_count = pod5_cr_get_read_complete_sample_count(reader : Reader*, batch : Batch*, batch_row : LibC::SizeT, sample_count : LibC::SizeT*) : Int32
  fun get_read_complete_signal = pod5_cr_get_read_complete_signal(reader : Reader*, batch : Batch*, batch_row : LibC::SizeT, sample_count : LibC::SizeT, signal : Int16*) : Int32
  fun create_file = pod5_cr_create_file(filename : UInt8*, writer_name : UInt8*, options : Pod5WriterOptions*) : Writer*
  fun close_and_free_writer = pod5_cr_close_and_free_writer(file : Writer*) : Int32
  fun add_pore = pod5_cr_add_pore(pore_index : Int16*, file : Writer*, pore_type : UInt8*) : Int32
  fun add_run_info = pod5_cr_add_run_info(run_info_index : Int16*, file : Writer*, acquisition_id : UInt8*, acquisition_start_time_ms : Int64, adc_max : Int16, adc_min : Int16, context_tags_count : LibC::SizeT, context_tags_keys : UInt8**, context_tags_values : UInt8**, experiment_name : UInt8*, flow_cell_id : UInt8*, flow_cell_product_code : UInt8*, protocol_name : UInt8*, protocol_run_id : UInt8*, protocol_start_time_ms : Int64, sample_id : UInt8*, sample_rate : UInt16, sequencing_kit : UInt8*, sequencer_position : UInt8*, sequencer_position_type : UInt8*, software : UInt8*, system_name : UInt8*, system_type : UInt8*, tracking_id_count : LibC::SizeT, tracking_id_keys : UInt8**, tracking_id_values : UInt8**) : Int32
  fun add_reads_data = pod5_cr_add_reads_data(file : Writer*, read_count : UInt32, struct_version : UInt16, row_data : Void*, signal : Int16**, signal_size : UInt32*) : Int32
  fun add_reads_data_pre_compressed = pod5_cr_add_reads_data_pre_compressed(file : Writer*, read_count : UInt32, struct_version : UInt16, row_data : Void*, compressed_signal : UInt8***, compressed_signal_size : LibC::SizeT**, sample_counts : UInt32**, signal_chunk_count : LibC::SizeT*) : Int32
  fun vbz_compressed_signal_max_size = pod5_cr_vbz_compressed_signal_max_size(sample_count : LibC::SizeT) : LibC::SizeT
  fun vbz_compress_signal = pod5_cr_vbz_compress_signal(signal : Int16*, signal_size : LibC::SizeT, compressed_signal_out : UInt8*, compressed_signal_size : LibC::SizeT*) : Int32
  fun vbz_decompress_signal = pod5_cr_vbz_decompress_signal(compressed_signal : UInt8*, compressed_signal_size : LibC::SizeT, sample_count : LibC::SizeT, signal_out : Int16*) : Int32
  fun format_read_id = pod5_cr_format_read_id(read_id : UInt8*, read_id_string : UInt8*) : Int32
end
