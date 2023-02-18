# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# If you use this file then you must apply the LICENSE file at the root of this project.

require "singleton"

module RripRedux
module Preferences
  class Main
    include Singleton

    attr_reader :data, :out
    attr_accessor :filename

    def initialize(out=nil)
      @data = Data.new
      @filename = get_default_filename
      @out = out || $stdout
    end

    # Load the preferences after setting the defaults
    def load(custom_filename="")
      SetDefaults.new
      Load.new(custom_filename, out)
      Cleanup.new.migrate_freedb_to_gnudb
    end

    # Save the preferences
    def save
      Save.new unless data.testdisc
    end

   private

    # If the method is not found try to look it up in the data object
    def method_missing(name, *args)
      data.send(name, *args)
    end

    # Return the default filename
    def get_default_filename
      dir = ENV["XDG_CONFIG_HOME"] || File.join(ENV["HOME"], ".config")
      File.join(dir, "rrip_redux/settings")
    end
  end # Main

  def self.show_filename_normal(basedir, layout)
    filename = File.expand_path(File.join(basedir, layout))
    filename = "%s.ext" % [filename]

    @substs_normal ||= {
      "%a" => "Judas Priest", "%b" => "Sin After Sin", "%f" => "codec",
      "%g" => "Rock", "%y" => "1977", "%n" => "01", "%t" => "Sinner",
      "%i" => "inputfile", "%o" => "outputfile"
    }

    @substs_normal.each { |key, value| filename.gsub!(key, value) }

    Metadata::FilterDirs.new(nil).filter(filename)
  end

  def self.show_filename_various(basedir, layout)
    filename = File.expand_path(File.join(basedir, layout))
    filename = "%s.ext" % [filename]

    @substs_various ||= {
      "%va" => "Various Artists", "%b" => "TMF Rockzone", "%f" => "codec",
      "%g" => "Rock", "%y" => "1999", "%n" => "01", "%a" => "Kid Rock",
      "%t" => "Cowboy"
    }

    @substs_various.each { |key, value| filename.gsub!(key, value) }

    Metadata::FilterDirs.new(nil).filter(filename)
  end
end
end
