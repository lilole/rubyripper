# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# If you use this file then you must apply the LICENSE file at the root of this project.

require 'pty'
require 'tmpdir'

module RripRedux
module System
  # This class manages the executing of external commands.
  # A separate class allows unified checking of exit status.
  # Also it allows for better unit testing, since it is easily mocked.
  #
  class Execute
    attr_reader :deps, :filename, :prefs

    def initialize(deps=nil, prefs=nil)
      @deps = deps || Dependency.instance
      @prefs = prefs || RripRedux::Preferences::Main.instance
    end

    # Return a temporary filename.
    #
    def get_temp_file(name)
      File.join(Dir.tmpdir, name)
    end

    # Return output for command.
    # Clear the file if it exists before the program runs.
    #
    def launch(command, filename=false, no_translations=nil)
      return true if command.empty?
      program = command.split[0]
      command = "LC_ALL=C; #{command}" if no_translations
      puts "DEBUG: #{command}" if prefs.debug

      if deps.installed?(program)
        File.delete(filename) if filename && File.exist?(filename)
        begin
          output = []
          PTY.spawn(command) do |stdin, stdout, pid|
            begin
              stdin.each { |line| output << line }
            rescue Errno::EIO
              # Normal end of input stream
            rescue Exception => exception
              puts "DEBUG: Command #{command} failed with exception: #{exception.message}" if prefs.debug
              output = nil
            end
          end
        rescue
          puts RripRedux::Errors.failed_to_execute(program, command)
          output = nil
        end
        @filename = filename
      else
        puts RripRedux::Errors.binary_not_found(program)
        output = nil
      end

      if    output.nil?   then output = [] # Sentinel for error
      elsif output.empty? then output = ["OK"] # Command finished ok with no output
      end
      output
    end

    # Return created file with command.
    #
    def read_file
      return File.read(filename) if File.exists?(filename)
    end
  end
end
end
