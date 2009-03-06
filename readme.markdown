SemiDaemon
==========

Why
---

Before this I've tried `backgroundDRB`, `daemon_generator` (I think that's the name), and they never really worked to my satisfaction.  I did find `background_job` for scheduled background stuff and liked how simple it was to setup and get started.  SemiDaemon is kind of patterned after the simplicity of setting up it's daemon process.


An example class
----------------

    class CampaignSender < SemiDaemon
  
      # defaulted based on the name of the class if you don't provide them
      # log and pid will both be stored in your RAILS_ROOT/log folder
      log_file "campaign_sender.log"
      pid_file "campaign_sender.pid"

      # you must provide an interval that your work function is called
      interval 2.hours
  
      # your work function is called every 2 hours
      def work
        logger.info "Running the queue..."
        Campaign.run_queue!
      rescue StandardError => e
        logger.error "-----"
        logger.error e.message
        e.backtrace.each { |x| logger.error x }
        logger.error "-----"
      end
  
    end

Setting it up with crontab
--------------------------

The following cron entry will start the daemon every hour.  If the process is already running them the new process will simply quit.

    0 * * * * /usr/bin/ruby /u/apps/your_app/current/script/runner -e production "CampaignSender.new.run"
    
If the process every dies for any reason cron will notify you of the stack trace via e-mail.  And one hour (or less) later the process will fire itself back up again.


Enjoy,
Josh Goebel