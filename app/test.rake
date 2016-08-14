desc 'Test'
task :test do
  puts "WNUM:           #{ENV['WNUM']}"
  puts "API_URL:        #{ENV['API_URL']}"
  puts "CLIENT_ID:      #{ENV['CLIENT_ID']}"
  puts "CLIENT_SECRET:  #{ENV['CLIENT_SECRET']}"
  puts "REFRESH_TOKEN:  #{ENV['REFRESH_TOKEN']}"
  puts "FREE SPACE:     #{`df -BG /home`.split[10].to_i}"
end
