# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# If you use this file then you must apply the LICENSE file at the root of this project.

require "singleton"

module RripRedux
module System
  # The Dependency class is responsible for all dependency checking.
  #
  class Dependency
    include Singleton
    include GetText; GetText.bindtextdomain("rrip_redux")
    def self._(txt) GetText._(txt) end

    attr_reader :deps, :exec, :file, :forced_deps, :optional_deps, :platform, :runtime, :verbose

    def initialize(file=nil, platform=nil)
      @platform = platform || RUBY_PLATFORM
      @file = file || File
    end

    # Should be triggered by any user interface.
    #
    def startup_check
      check_forced_deps
    end

    def eject(cdrom)
      Thread.new do
        @exec = Execute.new
        if installed?("eject")
          exec.launch("eject #{cdrom}")
        elsif installed?("diskutil") # For Mac users
          exec.launch("diskutil eject #{cdrom}")
        else
          puts _("WARNING: No eject utility found!")
        end
      end
    end

    def close_tray(cdrom)
      if installed?("eject")
        exec.launch("eject --trayclose #{cdrom}")
      end
    end

    # Verify all dependencies are met.
    # * verbose = print extra info to the terminal. Used in configure script.
    # * runtime = exit when needed deps aren't met.
    #
    def verify(verbose=false, runtime=true)
      @verbose = verbose
      @runtime = runtime
      check_forced_deps
      check_optional_deps
      @deps = array_to_hash(forced_deps + optional_deps)

      show_info if !! verbose
      force_deps_runtime if !! runtime
    end

    def env(var)
      return ENV[var]
    end

    # An array with dirs in which binary files are launchable.
    #
    def path
      ENV["PATH"].split(":") + ["."]
    end

    # Find the default programs if not set before.
    def filemanager() get_filemanager end
    def editor()      get_editor      end
    def browser()     get_browser     end

    # Find the default drive for the OS.
    def cdrom() get_cdrom end

    # A help function to check if an application is installed.
    #
    def installed?(app)
      return File.executable?(app) if app[0] == "/"
      path.each do |dir|
        return true if File.exist?(File.join(dir, app))
      end
      false
    end

  private

    # Fill the Hash with consequences.
    #
    def consequence
      @consequence ||= {
        "cdparanoia"   => _("Rubyripper can't be used without cdparanoia!"),
        "ruby-gtk3"    => _("You won't be able to use the gtk3 interface."),
        "ruby-gettext" => _("You won't be able to use translations."),
        "discid"       => _("You won't have accurate Gnudb string calculation unless %s is installed.") % ["Cd-discid"],
        "cd-discid"    => _("You won't have accurate Gnudb string calculation unless %s is installed.") % ["Discid"],
        "eject"        => _("Your disc tray can not be opened after ripping."),
        "flac"         => _("You won't be able to encode in FLAC."),
        "vorbis"       => _("You won't be able to encode in Vorbis."),
        "lame"         => _("You won't be able to encode in LAME mp3."),
        "wavegain"     => _("You won't be able to replaygain WAV files."),
        "vorbisgain"   => _("You won't be able to replaygain Vorbis files."),
        "mp3gain"      => _("You won't be able to replaygain LAME mp3 files."),
        "normalize"    => _("You won't be able to normalize audio files."),
        "cdrdao"       => _("You won't be able to make cuesheets."),
        "cd-info"      => _("Cd-info helps to detect data tracks."),
        "ls"           => _("Show rights in case of problems.")
      }
    end

    # Convert the arrays to hashes (they were arrays to prevent random sorting).
    #
    def array_to_hash(array)
      {}.tap do |result|
        array.each { |k, v| result[k] = v }
      end
    end

    # Check if all the forced dependencies are there.
    #
    def check_forced_deps
      @forced_deps = [].tap do |arr|
        arr << ["cdparanoia", installed?("cdparanoia")]
      end
    end

    # Check if all the optional dependencies are there.
    #
    def check_optional_deps
      @optional_deps = [].tap do |arr|
        arr << ["ruby-gtk3",    is_gtk3_found]
        arr << ["ruby-gettext", is_gettext_found]
        arr << ["discid",       installed?("discid")]
        arr << ["cd-discid",    installed?("cd-discid")]
        arr << ["eject",        installed?("eject") || installed?("diskutil")]

        # Codecs
        arr << ["flac",   installed?("flac")]
        arr << ["vorbis", installed?("oggenc")]
        arr << ["lame",   installed?("lame")]

        # Replaygain / normalize
        arr << ["wavegain",   installed?("wavegain")]
        arr << ["vorbisgain", installed?("vorbisgain")]
        arr << ["mp3gain",    installed?("mp3gain")]
        arr << ["normalize",  installed?("normalize") || installed?("normalize-audio")]

        # Extra apps
        arr << ["cdrdao",   installed?("cdrdao")]
        arr << ["cd-info",  installed?("cd-info")]
        arr << ["ls",       installed?("ls")]
        arr << ["diskutil", installed?("diskutil")]
      end
    end

    def is_gtk3_found
      require "gtk3"
      true
    rescue LoadError
      false
    end

    def is_gettext_found
      require "gettext"
      true
    rescue LoadError
      false
    end

    # Show the results in a terminal.
    #
    def show_info
      print _("\n\nCHECKING FORCED DEPENDENCIES\n\n")
      print_results(forced_deps)
      print _("\nCHECKING OPTIONAL DEPENDENCIES\n\n")
      print_results(optional_deps)
      print "\n\n"
    end

    # Iterate over the deps and show the details.
    #
    def print_results(deps)
      deps.each do |key, value|
        if !! value
          puts "#{key}: [OK]"
        else
          puts "#{key}: [NOT OK]"
          puts consequence[key] if consequence.key?(key)
        end
      end
    end

    # When running make sure the forced deps are there.
    #
    def force_deps_runtime
      if ! deps["cdparanoia"]
        puts "Cdparanoia not found on your system."
        puts "This is required to run Rrip_redux. Exiting..."
        exit(1)
      end
    end

    # Determine default file manager.
    #
    def get_filemanager
      case
      when ENV["DESKTOP_SESSION"] == "kde" && installed?("dolphin")   then "dolphin"
      when ENV["DESKTOP_SESSION"] == "kde" && installed?("konqueror") then "konqueror"
      when installed?("thunar")                                       then "thunar" # Xfce4
      when installed?("nautilus")                                     then "nautilus --no-desktop" # Gnome
      else "echo"
      end
    end

    # Determine default editor.
    #
    def get_editor
      case
      when ENV["DESKTOP_SESSION"] == "kde" && installed?("kwrite") then "kwrite"
      when installed?("mousepad")                                  then "mousepad" # Xfce4
      when installed?("gedit")                                     then "gedit" # Gnome
      when ENV.key?("EDITOR")                                      then ENV["EDITOR"]
      else "echo"
      end
    end

    # Determine default browser.
    #
    def get_browser
      case
      # Try to sort these from least to most common
      when ENV.key?("BROWSER")                                        then ENV["BROWSER"]
      when installed?("konqueror") && ENV["DESKTOP_SESSION"] == "kde" then "konqueror"
      when installed?("epiphany")                                     then "epiphany"
      when installed?("brave")                                        then "brave"
      when installed?("opera")                                        then "opera"
      when installed?("firefox")                                      then "firefox"
      when installed?("chromium")                                     then "chromium"
      else "echo"
      end
    end

    # Determine default drive, for different OSes.
    #
    def get_cdrom
      case platform
      when /freebsd/   then drive = get_freebsd_drive
      when /openbsd/   then drive = "/dev/cd0c" # As provided in issue 324
      when /linux|bsd/ then drive = get_linux_drive
      when /darwin/    then drive = "/dev/disk1"
      else drive = nil
      end
      drive || "unknown"
    end

    def get_freebsd_drive
      (0..9).map { |i| "/dev/cd#{i}"  }.each { |dev| return dev if file.exist?(dev) }
      (0..9).map { |i| "/dev/acd#{i}" }.each { |dev| return dev if file.exist?(dev) }
      false
    end

    def get_linux_drive
      return "/dev/cdrom"  if file.exist?("/dev/cdrom")
      return "/dev/dvdrom" if file.exist?("/dev/dvdrom")
      (0..9).map { |i| "/dev/sr#{i}" }.each { |dev| return dev if file.exist?(dev) }
      false
    end
  end
end
end
