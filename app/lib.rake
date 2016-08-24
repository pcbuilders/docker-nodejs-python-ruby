require 'eventmachine'
require 'logger'
require 'httparty'
require 'active_support/all'

def bigo_api
  ENV['API_URL']
end

def bigo_volume
  "/var/dataku/#{ENV['WNUM']}"
end

def bigo_fname(obj)
  "bigo_#{obj['bigo_id']}_#{obj['id']}_#{obj['sid']}_#{obj['room_id']}_#{obj['time']}.mp4"
end

def bigo_fullpath(fname)
  "#{bigo_volume}/#{fname}"
end

def bigo_file?(fname)
  File.file?(bigo_fullpath(fname))
end

def bigo_error(id, comment)
  bigo_req(:do => 'error', :id => id, :comment => comment)
end

def bigo_req(query={})
  begin
    req   = HTTParty.get(bigo_api, :query => query.merge(:wnum => ENV['WNUM']))
    if req.response.code == '200'
      return req.parsed_response
    end
  rescue => e
    puts e
    logger.info(e)
  end

  return false
end

def bigo_unstreamed(obj)
  succ = false
  fname  = bigo_fname(obj)
  if !bigo_file?(fname)
    if free_space > 1
      begin
        req = HTTParty.head("http://live.bigo.tv/#{obj['sid']}", :follow_redirects => false, :headers => {'User-Agent' => ua})
      rescue
        return false
      end
      uri = req.headers['location']

      if !uri
        logger.warn("#{obj['id']} live ended")
        bigo_error(obj['id'], "Live ended")
      else
        succ = true
        stream_url = "#{uri.scheme}://#{uri.host}:#{uri.port}/list_#{uri.query.split('&').first}.m3u8"
        `nohup livestreamer -Q --yes-run-as-root -o #{bigo_fullpath(fname)} 'hls://#{stream_url}' best > /dev/null 2>&1 &`
        logger.info("livestreamer -Q -o #{bigo_fullpath(fname)} 'hls://#{stream_url}' best")
        logger.info("#{obj['id']} streamed")
      end
    else
      logger.warn("#{obj['id']} Space FULL")
    end
  else
    succ = true
  end
  
  if succ
    bigo_req(:do => 'streamed', :id => obj['id'])
  end
  return nil
end

def bigo_uncompleted(obj)
  fname = bigo_fname(obj)
  
  nstep   = false
  attempt = 0
  begin
    if !bigo_file?(fname)
      sleep 1
      attempt += 1
    else
      nstep = true
    end
  end until (attempt > 10 || nstep)
  
  if nstep
    fsize         = File.size(bigo_fullpath(fname))
    sleep 15
    current_size  = File.size(bigo_fullpath(fname))
    if fsize == current_size
      logger.info("#{obj['id']} completed")
      bigo_req(:do => 'completed', :id => obj['id'])
    end
  else
    logger.warn("#{obj['id']} stream not found")
    bigo_error(obj['id'], "Stream not found")
  end
end

def bigo_unuploaded(obj)
  fname = bigo_fname(obj)
  if !bigo_file?(fname)
    logger.warn("#{obj['id']} file not found")
    bigo_error(obj['id'], "File not found")
  else
    `nohup node drive.js --id "#{obj['id']}" --name "#{fname}" > /dev/null 2>&1 &`
    logger.info("#{obj['id']} uploading")
    bigo_req(:do => 'uploading', :id => obj['id'])
  end
end

def ua
  "Mozilla/5.0 (Linux; Android 4.4.2; Nexus 4 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.114 Mobile Safari/537.36"
end

def free_space
  `df -BG #{bigo_volume}`.split[10].to_i
end

def logger
  Logger.new(STDOUT)
end
