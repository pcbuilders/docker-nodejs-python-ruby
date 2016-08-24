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
        req.each do |x|
          bigo_uncompleted(x)
        end
      end
      logger.info("Uncompleted DONE")
    end
  end
end

desc 'Get unuploaded shows'
task :unuploaded do
  EM.run do
    EM.add_periodic_timer(5) do
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
