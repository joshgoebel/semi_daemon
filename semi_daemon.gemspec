require 'lib/semi_daemon/version'

version = SemiDaemon::Version::FULL

Gem::Specification.new do |s|
  s.name = "semi_daemon"
  s.version = version
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  
  s.author="Josh Goebel"
  s.email = "josh@autoraptor.com"
  s.summary = "simple class for creating long running daemon processes"
  s.description = "simple class for creating long running daemon processes easily"
  
  s.extra_rdoc_files = [ "readme.markdown" ]
  s.files= %w(Rakefile) + Dir.glob("lib/**/*") + 
    Dir.glob("test/**/*") +
    Dir.glob("vendor/**/*")
  
  s.require_path = "lib"
  # s.extensions = FileList["ext/**/extconf.rb"].to_a
  # s.bindir = "bin"
  
  # s.add_dependency("rails",">= 3.0")
end
