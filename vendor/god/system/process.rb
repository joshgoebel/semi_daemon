module God
  module System
  
    class Process
      def initialize(pid)
        @pid = pid.to_i
      end
      
      # Return true if this process is running, false otherwise
      def exists?
        !!::Process.kill(0, @pid) rescue false
      end
      
    end
  
  end
end