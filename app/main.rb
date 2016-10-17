#!/usr/bin/env ruby

#Process.daemon(true)

require_relative '/app/streamer'

Dir.mkdir('/app/pids') if !Dir.exist?('/app/pids')

loop do
  Streamer.new.start!
  sleep 5
end
