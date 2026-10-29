module Pod5
  VERSION        = "0.1.0"
  NATIVE_VERSION = "0.3.49"
  API_VERSION    = 7_u16

  enum EndReason
    Unknown
    MuxChange
    UnblockMuxChange
    DataServiceUnblockMuxChange
    SignalPositive
    SignalNegative
    ApiRequest
    DeviceDataError
    AnalysisConfigChange
    Paused
  end

  enum Compression : Int8
    Default      = 0
    VBZ          = 1
    Uncompressed = 2
  end

  class Error < Exception
    getter code : Int32

    def initialize(@code : Int32, message : String)
      super(message)
    end
  end

  class ClosedError < Exception
  end

  @@init_mutex = Mutex.new
  @@initialized = false

  # Process-wide registration is deliberately not undone by closing a file.
  # Calling LibPod5.terminate while wrappers are alive is unsupported.
  protected def self.init : Nil
    @@init_mutex.synchronize do
      unless @@initialized
        check(LibPod5.init, "initialize POD5")
        @@initialized = true
      end
    end
  end

  protected def self.check(code : Int32, operation : String) : Nil
    return if code == 0
    message = copy_string(LibPod5.get_error_string)
    raise Error.new(code, "#{operation}: #{message}")
  end

  protected def self.check_pointer(pointer : Pointer(T), operation : String) : Pointer(T) forall T
    if pointer.null?
      code = LibPod5.get_error_no
      code = 9 if code == 0
      check(code, operation)
    end
    pointer
  end

  protected def self.copy_string(pointer : Pointer(UInt8)) : String
    pointer.null? ? "" : String.new(pointer)
  end

  protected def self.copy_map(data : LibPod5::KeyValueData) : Hash(String, String)
    result = {} of String => String
    data.size.to_i.times do |i|
      result[copy_string(data.keys[i])] = copy_string(data.values[i])
    end
    result
  end

  protected def self.c_string(value : String, name : String) : String
    raise ArgumentError.new("#{name} contains a NUL byte") if value.includes?('\0')
    value
  end
end
