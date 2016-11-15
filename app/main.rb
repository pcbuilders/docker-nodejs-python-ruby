require_relative 'bigo_streamer'
loop do
  BigoStreamer.new.start!
  sleep 5
end
