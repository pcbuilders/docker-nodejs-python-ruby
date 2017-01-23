require 'httparty'
require 'logger'
require 'eventmachine'
require 'em-http-request'
require 'sys/proctable'

class BigoStreamer

  def initialize
    @logger = Logger.new(STDOUT)
  end
  
  def start!
    save_secrets
    unstreamed
    uncompleted
    unuploaded
    return false
  end

  private

  # Get secrets
  def save_secrets
    @logger.info("Save secrets START")
    req = api_request(:do => 'secrets')
    IO.write('secrets.json', req.to_json) if req
    @logger.info("Save secrets DONE")
    return false
  end

  # Get unstreamed objects
  def unstreamed
    @logger.info("Unstreamed START")
    if req = api_request(:do => 'unstreamed')
      iterate_unstreamed(req) if !req.empty?
    end
    @logger.info("Unstreamed DONE")
    return false
  end
  
  def iterate_unstreamed(req)
    return false if !enough_space?
    req.each_slice(5) do |req2|
      EM.run {
        m = EM::MultiRequest.new
        req2.each { |obj| m.add obj, EM::HttpRequest.new(live_uri(obj['sid']), :connect_timeout => 60, :inactivity_timeout => 60).get(:redirects => 1, :head => {"User-Agent" => user_agent}) }
        m.callback {
          m.responses[:callback].each { |obj, resp| proc_unstreamed(obj, resp) if !(resp.response.to_s =~ /uid failed/) && !resp.response.to_s.empty? }
          EM.stop
        }
      }
    end
    return false
  end
  
  def proc_unstreamed(obj, resp)

    return false if !enough_space?

    @obj = obj

    if !running?
      if m3u8_uri = resp.response.to_s.match(/list_(\d{10,})_(\d{10,})\.m3u8/i)
        `nohup livestreamer -Q --yes-run-as-root -o #{fullpath} --hls-timeout 300 --hls-segment-timeout 60 --http-header "Referer=#{resp.last_effective_url.to_s}" 'hls://#{stream_url(resp.last_effective_url, m3u8_uri.to_s)}' best > /dev/null 2>&1 &`
        streamed
      else
        error
      end
    else
      streamed
    end
    return false
  end
  
  def stream_url(uri, m3u8_uri)
    "#{uri.scheme}://#{uri.host}:#{uri.port}/#{m3u8_uri}"
  end
  
  # Get uncompleted objects
  def uncompleted
    @logger.info("Uncompleted START")
    if req = api_request(:do => 'uncompleted')
      req.each do |obj|
        @obj  = obj
        completed if done?
        error('Stream not found') if error?
      end
    end
    @logger.info("Uncompleted DONE")
    return false
  end

  # Process unuploaded objects
  def unuploaded
    @logger.info("Unuploaded START")
    if req = api_request(:do => 'unuploaded')
      req.each do |obj|
        @obj = obj
        `nohup node uploader.js --id #{@obj['id']} --name #{fname} > /dev/null 2>&1 &`
        uploading
      end
    end
    @logger.info("Unuploaded DONE")
    return false
  end

  def wnum
    ENV['WNUM']
  end

  def api
    ENV['API_URL']
  end

  def volume
    ['/var', 'dataku', wnum].join('/')
  end

  def fname
    ['bigo', @obj['bigo_id'], @obj['id'], @obj['sid'], @obj['room_id'], @obj['time']].join('_') + '.mp4'
  end

  def fullpath
    [volume, fname].join('/')
  end

  def file_exist?
    File.file? fullpath
  end

  def running?
    file_exist? || process_exist?
  end
  
  def error?
    !file_exist? && !process_exist?
  end

  def process_exist?
    !Sys::ProcTable.ps.map(&:cmdline).join.scan(fname).empty?
  end
  
  def done?
    file_exist? && !process_exist?
  end
  
  def enough_space?
    `df -BG #{volume}`.split[10].to_i >= 3
  end
  
  def live_uri(sid=nil)
    "http://#{ip}/#{sid || @obj['sid']}"
  end
  
  def ip
    "bgprx.abylina.com"
  end
  
  def user_agent
    "Mozilla/5.0 (Android; Mobile; rv:29.0) Gecko/29.0 Firefox/29.0"
  end
  
  def streamed
    set_status('streamed')
  end
  
  def completed
    set_status('completed')
  end
  
  def uploading
    set_status('uploading')
  end

  def set_status(status)
    api_request(:do => status, :id => @obj['id'])
    @logger.info([@obj['id'], status].join(': '))
    return false
  end

  def error(comment='Live ended')
    api_request(:do => 'error', :id => @obj['id'], :comment => comment)
    @logger.warn([@obj['id'], 'error', comment].join(': '))
    return false
  end

  def api_request(query={})
    begin
      req   = HTTParty.get(api, :query => query.merge(:wnum => wnum), :timeout => 30)
      if req.response.code == '200'
        return req.parsed_response
      else
        raise "Response code not valid"
      end
    rescue => e
      @logger.info(e)
    end
    return false
  end
end
