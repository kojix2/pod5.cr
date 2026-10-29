module Pod5
  # A detached read. Owns a copy of its input signal and survives Reader#close.
  class Read
    @signal : Slice(Int16)
    include ReadAccess
    getter metadata : Metadata

    def initialize(@metadata : Metadata, signal : Slice(Int16))
      @signal = signal.dup
    end

    def sample_count : UInt64
      @signal.size.to_u64
    end

    # Returns the owned, mutable buffer. No native memory is exposed.
    def signal : Slice(Int16)
      @signal
    end
  end

  # Metadata is owned. Signal access requires the source Reader to remain open.
  # Records never reuse another record's metadata or signal buffer.
  class Record
    include ReadAccess
    getter metadata : Metadata
    getter sample_count : UInt64
    getter table_version : UInt16

    protected def initialize(@reader : Reader, @batch_index : Int32, @row_index : Int32,
                             @metadata : Metadata, @sample_count : UInt64,
                             @table_version : UInt16)
    end

    # Reads into a new GC-owned buffer on every call; not implicitly cached.
    def signal : Slice(Int16)
      result = Slice(Int16).new(@sample_count.to_i)
      signal_into(result)
    end

    # The buffer must contain exactly sample_count Int16 elements.
    def signal_into(buffer : Slice(Int16)) : Slice(Int16)
      raise ArgumentError.new("signal buffer has wrong sample count") unless buffer.size.to_u64 == @sample_count
      @reader.read_signal(@batch_index, @row_index, buffer)
      buffer
    end

    def materialize : Read
      Read.new(@metadata, signal)
    end
  end
end
