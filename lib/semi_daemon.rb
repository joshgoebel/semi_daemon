require File.dirname(__FILE__) + "/../vendor/god/system/process"

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

    def stop_file
      "#{daemon_name}.stop"
    end

  end
  
  # create instance methods for our class methods
  def method_missing(m,*args)
    if [:log_file, :pid_file, :interval, :daemon_name,:stop_file].include?(m)
      self.class.send(m) 
    else
      super(m,*args)
    end
  end
  
  # logging

  def logger
    @logger ||= begin
      l=Logger.new root("log/#{log_file}")
      l.formatter = SimpleLogFormatter.new
      l
    end
  end

  # process management
  
  def root(path)
    if defined?(Rails)
      (Rails.root + path).to_s
    else
      dir = File.dirname(__FILE__)
      path[0..0]=="/" ? path : File.join(dir, path)
    end
  end

  def stop_file_path
    root stop_file
  end
  
  def pid_file_path
    root pid_file
  end

  def create_pid_file
    File.open(pid_file_path,"w") { |f| f.write(Process.pid) }
  end

  def running?
     if File.exists?(pid_file_path)
       pid=File.read(pid_file_path)
       God::System::Process.new(pid).exists?
     end
   end
  
  def work
    raise "You need to define the work method in your subclass of SemiDaemon."
  end
  
  def terminate
    logger.info "#{daemon_name} stopped."
    Rails.logger.info "#{daemon_name} stopped." if defined?(Rails)
    File.delete(pid_file_path) rescue nil
    File.delete(stop_file_path) rescue nil
    exit
  end
  
  def transaction(&block)
    terminate if @quit
    @safe_to_quit=false
    r=block.call
    @safe_to_quit=true
    terminate if @quit
    r
  end
  
  def initialize
    @safe_to_quit=true
  end
  
  def wants_quit?
    File.exists?(stop_file_path) or @quit
  end
  
  def run
    raise "You must specify `interval 1.minute` or similar in your class to set the interval." if interval.nil?
    return if running?
    Signal.trap("TERM") do 
      @quit=true
      # if it's not safe to quit then we have to trust that our
      # child class will quit when it can or else we'll quit at
      # the beginning of the next event loop
      terminate if @safe_to_quit
    end

    create_pid_file
    logger.info "#{daemon_name} started (PID: #{Process.pid})."
    while(true)
      if wants_quit?
        logger.info "Being asked to stop (#{@quit ? "TERM" : "stop file"}), stopping..."
        terminate
      end
      logger.info "Working..."
      work
      if defined?(ActiveRecord::Base)
        ActiveRecord::Base.clear_active_connections! 
      end
      logger.info "Sleeping for #{interval/60} minutes..."
      # we do this so we can stop more quickly while sleeping
      interval.to_i.times { sleep 1 unless @quit }
    end
  end
  
end