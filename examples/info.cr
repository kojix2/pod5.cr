require "../src/pod5"

if ARGV.size != 1
  STDERR.puts "Usage: pod5-info FILE.pod5"
  exit 1
end

begin
  Pod5::Reader.open(ARGV[0]) do |reader|
    puts "file_id\t#{reader.file_identifier}"
    puts "pod5_version\t#{reader.file_version}"
    puts "reads\t#{reader.size}"
    puts "batches\t#{reader.batch_count}"
    puts "read_id\tchannel\twell\tsamples\tduration_seconds\tread_number"
    reader.each do |read|
      puts "#{read.read_id}\t#{read.channel}\t#{read.well}\t#{read.sample_count}\t#{read.duration}\t#{read.read_number}"
    end
  end
rescue ex : Pod5::Error | Pod5::ClosedError
  STDERR.puts ex.message
  exit 1
end
