module Pod5
  module VBZ
    def self.compress(signal : Slice(Int16)) : Bytes
      Pod5.init
      capacity = LibPod5.vbz_compressed_signal_max_size(signal.size)
      Pod5.check(LibPod5.get_error_no, "VBZ maximum size") if capacity == 0
      output = Bytes.new(capacity.to_i)
      size = LibC::SizeT.new(output.size)
      dummy = 0_i16
      pointer = signal.empty? ? pointerof(dummy) : signal.to_unsafe
      Pod5.check(LibPod5.vbz_compress_signal(pointer, signal.size, output, pointerof(size)), "VBZ compress")
      output[0, size.to_i]
    end

    def self.decompress(data : Bytes, sample_count : Int) : Slice(Int16)
      raise ArgumentError.new("sample_count must not be negative") if sample_count < 0
      result = Slice(Int16).new(sample_count.to_i)
      decompress_into(data, result)
    end

    def self.decompress_into(data : Bytes, output : Slice(Int16)) : Slice(Int16)
      Pod5.init
      raise ArgumentError.new("compressed data must not be empty") if data.empty?
      dummy = 0_i16
      pointer = output.empty? ? pointerof(dummy) : output.to_unsafe
      Pod5.check(LibPod5.vbz_decompress_signal(data, data.size, output.size, pointer), "VBZ decompress")
      output
    end
  end
end
