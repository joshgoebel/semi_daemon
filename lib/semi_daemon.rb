class SemiDaemon

  class SimpleLogFormatter
    def call(severity, time, progname, msg)
      "#{time.strftime("%Y-%m-%d %H:%M:%S")}: #{msg}\n"
    end
  end
  
  class << self

    def daemon_name
      self.to_s.underscore
    end
    
    def log_file(log=nil)
      log ? @log_file=log : @log_file
    end
  
    def pid_file(pid_file=nil)
      pid_file ? @pid_file=pid_file : @pid_file
    end    
  
    def interval(int=nil)
      int ? @interval=int : @interval
    end
    
    def inherited(child)
      child.log_file "#{child.daemon_name}.log"
      child.pid_file "#{child.daemon_name}.pid"
    end

  end
  
  def method_missing(m,*args)
    if [:log_file, :pid_file, :interval, :daemon_name].include?(m)
      self.class.send(m) 
    else
      super(m,*args)
    end
  end
  
  # logging

  def logger
    @logger ||= begin
      l=Logger.new(File.join(RAILS_ROOT, "log", log_file))
      # undo some of the damage Rails does to the default logger
      def l.format_message(*args) old_format_message(*args) end
      l.formatter = SimpleLogFormatter.new
      l
    end
  end

  # process management

  def pid_file_path
    return pid_file if pid_file.include?("/")
    File.join(RAILS_ROOT,"log",pid_file)    
  end

  def create_pid_file
    File.new(pid_file_path,"w") { |f| f.write(Process.pid) }
  end

  def running?
     if File.exists?(pid_file)
       pid=File.read(pid_file)
       God::System::Process.new(pid).exists?
     end
   end
  
  def work
    raise "You need to define the work method in your subclass of SemiDaemon."
  end
  
  def run
    raise "You must specify `interval 1.minute` or similar in your class to set the interval." if interval.nil?
    return if running?
    Signal.trap("TERM") do 
      ActiveRecord::Base.logger.info "#{daemon_name} stopped."
      File.delete(pid_file) rescue nil
    end

    create_pid_file
    logger.info "#{daemon_name} started (PID: #{Process.pid})."
    while(true)
      logger.info "Working..."
      work
      ActiveRecord::Base.clear_active_connections!
      logger.info "Sleeping for #{interval/60} minutes..."
      # we do this so we can interrupt more easily while we're sleeping
      mini=self.class.interval/5
      mini.times { sleep 5 }
    end
  end
  
end