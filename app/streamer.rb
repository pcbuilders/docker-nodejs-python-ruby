require 'httparty'
require 'logger'
require 'sys/proctable'

class Streamer

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
    if (!File.file?('secrets.json') || File.mtime('secrets.json').hour < Time.now.hour)
      req = api_request(:do => 'secrets')
      IO.write('secrets.json', req.to_json) if req
    end
    @logger.info("Save secrets DONE")
    return false
  end

  # Get unstreamed objects
  def unstreamed
    @logger.info("Unstreamed START")
    if req = api_request(:do => 'unstreamed')
      req.each do |obj|
        @obj  = obj
        proc_unstreameed
      end
    end
    @logger.info("Unstreamed DONE")
    return false
  end
  
  def proc_unstreamed
    return false if !enough_space?
    if !running?
      if live = is_live?
        Process.detach Process.spwan(stream_cmd(URI.parse(live)), [:err, :out] => '/dev/null')
        streamed
      else
        error if live == nil
      end
    else
      streamed
    end
    return false
  end
  
  def stream_cmd(uri)
    ['livestreamer', '-Q', '--yes-run-as-root', '-o', fullpath, "hls://#{uri.scheme}://#{uri.host}:#{uri.port}/list_#{uri.query.split('&').first}.m3u8", 'best'].join(' ')
  end
  
  # Get uncompleted objects
  def uncompleted
    @logger.info("Unstreamed START")
    if req = api_request(:do => 'uncompleted')
      req.each do |obj|
        @obj  = obj
        completed if done?
        error('Stream not found') if !running?
      end
    end
    @logger.info("Unstreamed DONE")
    return false
  end

  # Process unuploaded objects
  def unuploaded
    @logger.info("Unuploaded START")
    if req = api_request(:do => 'unuploaded')
      req.each do |obj|
        @obj = obj
        Process.detach Process.spawn(['node', 'uploader.js', '--id', @obj['id'], '--name', fname].join(' '), [:err, :out] => '/dev/null')
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

  def process_exist?
    !Sys::ProcTable.ps.map(&:cmdline).join.scan(fname).empty?
  end
  
  def done?
    file_exist? && !process_exist?
  end
  
  def enough_space?
    `df -BG #{volume}`.split[10].to_i >= 3
  end

  def is_live?
    begin
      HTTParty.head("http://web.live.bigo.sg/#{@obj['sid']}", :headers => {'User-Agent' => 'okhttp3'}, :follow_redirects => false, :timeout => 30).headers['location']
    rescue => e
      @logger.warn([@obj['id'], 'check is live error', e].join(': '))
      return false
    end
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
