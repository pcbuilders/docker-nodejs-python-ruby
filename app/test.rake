desc 'Test'
task :test do
  puts "WNUM:                   #{ENV['WNUM']}"
  puts "API_COOKIE:             #{ENV['API_COOKIE']}"
  puts "X_GUPLOADER_CLIENT_ID:  #{ENV['X_GUPLOADER_CLIENT_ID']}"
  puts "EFFECTIVE_ID:           #{ENV['EFFECTIVE_ID']}"
  puts "API_URL:                #{ENV['API_URL']}"
  puts "API_UPLOAD_URL:         #{ENV['API_UPLOAD_URL']}"
  puts "FREE SPACE:             #{`df -BG /home`.split[10].to_i}"
end
