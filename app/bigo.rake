require 'sys/proctable'

desc 'Get unstreamed shows'
task :unstreamed do
  EM.run do
    EM.add_periodic_timer(5) do
      logger.info("Unstreamed START")
      req   = bigo_req(:do => 'unstreamed')
      if req
        req.each do |x|
          bigo_unstreamed(x)
        end
      end
      logger.info("Unstreamed DONE")
    end
  end
end

desc 'Get uncompleted shows'
task :uncompleted do
  EM.run do
    EM.add_periodic_timer(17) do
      logger.info("Uncompleted START")
      req   = bigo_req(:do => 'uncompleted')
      if req
        processes = Sys::ProcTable.ps.map(&:cmdline).join
        req.each do |obj|
          fname = bigo_fname(obj)
          if !bigo_file?(fname)
            logger.warn("#{obj['id']} stream not found")
            bigo_error(obj['id'], "Stream not found") rescue nil
          else
            if processes.scan(fname).blank?
              logger.info("#{obj['id']} completed")
              bigo_req(:do => 'completed', :id => obj['id']) rescue nil
            end
          end
          #bigo_uncompleted(x)
        end
      end
      logger.info("Uncompleted DONE")
    end
  end
end

desc 'Get unuploaded shows'
task :unuploaded do
  EM.run do
    EM.add_periodic_timer(23) do
      logger.info("Unuploaded START")
      req   = bigo_req(:do => 'unuploaded')
      if req
        req.each do |x|
          bigo_unuploaded(x)
        end
      end
      logger.info("Unuploaded DONE")
    end
  end
end

desc 'Fetch credentials'
task :fetch_credentials do
  if !File.file?('secrets.json')
    save_secrets
  else
    EM.add_periodic_timer(86400) do
      save_secrets
    end
  end
end
