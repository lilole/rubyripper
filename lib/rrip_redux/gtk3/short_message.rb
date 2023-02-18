# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# If you use this file then you must apply the LICENSE file at the root of this project.

module RripRedux
module Gtk3
  # ShortMessage handles the rubyripper window while displaying a message.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class ShortMessage
    include GetText; GetText.bindtextdomain("rrip_redux")

    attr_reader :display, :prefs

    def initialize(prefs=nil)
      @prefs = prefs || RripRedux::Preferences::Main.instance
      @display = Gtk::Label.new('')
    end

    def scan
      _("...Scanning drive %s for an audio disc.") % [prefs.cdrom]
    end

    def welcome
      display.text = _("Welcome to Rrip_redux %s.") % [$app_version] + "\n\n" + scan
    end

    def refresh_disc
      display.text = scan
    end

    def no_disc_found
      display.text = _("No disc found in %s!\n" \
        "Please insert a disc and push 'Scan drive'.\n\n" \
        "The cdrom drive can be set in 'Preferences'.") % [prefs.cdrom]
    end

    def open_tray
      display.text = _("Opening tray of drive %s.") % [prefs.cdrom]
    end

    def close_tray
      display.text = _("Closing tray of the drive.") + "\n\n" + scan
    end

    def ask_for_disc
      display.text = _("Insert an audio-disc and press 'Close tray'.\n" \
        "The drive will automatically be scanned for a disc.\n\n" \
        "If the tray is already closed, press 'Scan drive'.")
    end

    def no_eject_found
      display.text = _("The eject utility is not found on your system!")
    end

    def show_error(error)
      display.text = RripRedux::Errors.send(error[0], error[1])
    end

    def show_message(message)
      display.text = message
    end
  end
end
end
