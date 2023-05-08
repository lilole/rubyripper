# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

module RripRedux
  # The Rubyripper window. It has a variable frame in it, that can be replaced with other Gtk3 classes.
  #
  class GraphicalUserInterface
    include GetText; GetText.bindtextdomain("rrip_redux")
    include RripRedux::Gtk3::GtkConstants

    QueueEntry = Struct.new(:modus, :value)

    attr_reader :buttons, :buttonicons, :buttontext, :current_instance, :deps, :dir_exists, :gtk_disc, :gtk_summary,
      :gtk_window, :instances, :main_hbox, :multiple_freedb_hits, :multiple_music_brainz_hits, :prefs, :rip_status,
      :rrip_redux, :rrip_redux_thread, :short_message, :update_queue, :vboxes, :vbuttonbox1

    def initialize(prefs=nil, short=nil, deps=nil)
      @prefs         = prefs || RripRedux::Preferences::Main.instance
      @short_message = short || RripRedux::Gtk3::GtkShortMessage.new
      @deps          = deps  || RripRedux::System::Dependency.instance
      @update_queue  = Queue.new
    end

    def start
      prefs.load
      prepare_main_window
      setup_main_container
      show_welcome_message
      gtk_window.show_all
      scan_disc
      Gtk.main
    end

    def show_disc
      scan_disc_results
    end

    def continue_rip
      update_interface_and_start_rip
    end

    # Send updates to the interface.
    #
    def update(modus, value=false)
      update_queue << QueueEntry.new(modus, value)
      GLib::Idle.add { process_update_queue }
    end

  private

    # Set the name, icon and size.
    #
    def prepare_main_window
      @gtk_window = Gtk::Window.new("RRip Redux")
      set_icon_for_window
      gtk_window.set_default_size(1280, 720) # Width, height
    end

    # Find the icon.
    #
    def set_icon_for_window
      icon_paths = [
        File.expand_path("../../share/icons/hicolor/128x128/apps", __FILE__),
        "/usr/local/share/icons/hicolor/128x128/apps"
      ]
      icon_paths.each do |path|
        file = File.join(path, "rrip_redux.png")
        next if ! File.exist?(file)
        gtk_window.icon = GdkPixbuf::Pixbuf.new(file: file)
        break
      end
    end

    # Setup the central container.
    #
    def setup_main_container
      @main_hbox = Gtk::Box.new(:horizontal, 5)
      create_buttons_leftside
      set_buttons_leftside_signals
      main_hbox.pack_start(vbuttonbox1, expand: false, fill: false, padding: 10)
      gtk_window.add(main_hbox)
    end

    # Launch the welcome message and announce the scanning.
    #
    def show_welcome_message
      short_message.welcome
      change_display(short_message)
    end

    def buttons_sensitive!(yes, *indexes)
      indexes = (0 ... buttons.size).to_a if indexes.empty?
      indexes.each { |i| buttons[i].sensitive = !! yes }
    end

    def scan_disc
      buttons_sensitive!(false)
      if gtk_disc
        gtk_disc.refresh
      else
        @gtk_disc = GtkDisc.new(self)
        gtk_disc.start
      end
    end

    # TODO: Cancel toc scan.
    #
    def scan_disc_results
      if gtk_disc.error.nil?
        gtk_disc.refresh_gui
        show_open_tray if buttontext[2].text != _("Open tray")
        buttons_sensitive!(true)
        change_display(gtk_disc)
      else
        short_message.show_error(gtk_disc.error)
        buttons_sensitive!(true, 0, 1, 2, 4)
        change_display(short_message)
      end
    end

    def show_multiple_records_selection
      meta_data_type = gtk_disc.disc.metadata.class.to_s
      if meta_data_type == "MusicBrainz"
        @multiple_music_brainz_hits = RripRedux::Gtk3::GtkMultipleMusicBrainzHits.new(gtk_disc.disc.metadata, self)
        change_display(multiple_music_brainz_hits)
      elsif meta_data_type == "Freedb"
        @multiple_freedb_hits = RripRedux::Gtk3::GtkMultipleFreedbHits.new(gtk_disc.disc.metadata, self)
        change_display(multiple_freedb_hits)
      else
        puts "ERROR: Unknown metadata type, check code!"
        update("scan_disc_finished")
      end
    end

    def process_update_queue
      if ! update_queue.empty?
        entry = update_queue.pop
        if entry.modus == "error"
          display_error_message(entry.value)
        elsif entry.modus == "error_msg_end"
          change_display(gtk_disc)
          buttons_sensitive!(true)
        elsif entry.modus == "ripping_progress"
          rip_status.update_progress("ripping", entry.value)
        elsif entry.modus == "encoding_progress"
          rip_status.update_progress("encoding", entry.value)
        elsif entry.modus == "log_change"
          rip_status.log_change(entry.value)
        elsif entry.modus == "scroll_to_end"
          rip_status.scroll_to_end
        elsif entry.modus == "dir_exists"
          @dir_exists = RripRedux::Gtk3::GtkDirExists.new(self, rrip_redux, entry.value)
          change_display(dir_exists)
        elsif entry.modus == "finished"
          show_summary(entry.value)
        elsif entry.modus == "scan_disc_finished"
          scan_disc_results
        elsif entry.modus == "scan_disc_metadata_mutiple_records"
          show_multiple_records_selection
        else
          puts _("Ehh.. There shouldn't be anything else. WTF?")
          puts _("Secret modus = %s") % [entry.modus]
        end
      end
      false
    end

    def display_error_message(message)
      short_message.show_message(message)
      change_display(short_message)
      Thread.new do
        sleep(5)
        update("error_msg_end")
      end
    end

    # The abort button transforms into exit when the rip is finished or aborted.
    #
    def update_abort_button_to_exit
      buttontext[4].set_markup("_" + _("Exit"), { use_underline: true })
      buttonicons[4].stock = gQUIT
    end

    # The exit button transforms into abort when the rip is started.
    #
    def update_exit_button_to_abort
      buttontext[4].set_markup("_" + _("Abort"), { use_underline: true })
      buttonicons[4].stock = gCANCEL
    end

    # The central function that manages the display on the right side.
    #
    def change_display(object)
      update_abort_button_to_exit if current_instance == "RipStatus"

      main_hbox.remove(main_hbox.children[-1]) if current_instance
      @current_instance = object.class.to_s # Save the name of the class as a string
      main_hbox.pack_start(object.display, expand: true, fill: true)

      update_exit_button_to_abort if current_instance == "RipStatus"
      object.display.show_all
    end

    # The leftside menu that is always visible.
    #
    def create_buttons_leftside
      @vbuttonbox1 = Gtk::Box.new(:vertical, 5) # Child of main_hbox
      vbuttonbox = Gtk::ButtonBox.new(:vertical)
      vbuttonbox.layout_style = gSTART
      vbuttonbox.spacing = 5

      @buttons = [Gtk::Button.new, Gtk::Button.new, Gtk::Button.new, Gtk::Button.new, Gtk::Button.new]
      buttons_sensitive!(false)

      @buttontext = [
        Gtk::Label.new("_" + _("Preferences"), { use_underline: true }),
        Gtk::Label.new("_" + _("Scan drive"),  { use_underline: true }),
        Gtk::Label.new("_" + _("Open tray"),   { use_underline: true }),
        Gtk::Label.new("_" + _("Rip cd now!"), { use_underline: true }),
        Gtk::Label.new("_" + _("Exit"),        { use_underline: true })
      ]
      @buttonicons = [
        Gtk::Image.new(stock: gPREFERENCES, size: gLARGE_TOOLBAR),
        Gtk::Image.new(stock: gREFRESH,     size: gLARGE_TOOLBAR),
        Gtk::Image.new(stock: gGOTO_BOTTOM, size: gLARGE_TOOLBAR),
        Gtk::Image.new(stock: gCDROM,       size: gLARGE_TOOLBAR),
        Gtk::Image.new(stock: gQUIT,        size: gLARGE_TOOLBAR)
      ]
      @vboxes = [
        Gtk::Box.new(:vertical, 5),
        Gtk::Box.new(:vertical, 5),
        Gtk::Box.new(:vertical, 5),
        Gtk::Box.new(:vertical, 5),
        Gtk::Box.new(:vertical, 5)
      ]

      vboxes.each_with_index do |vbox, index|
        vbox.add(buttonicons[index])
        vbox.add(buttontext[index])
        buttons[index].add(vboxes[index])
      end

      buttons.each { |button| vbuttonbox.pack_start(button, expand: false, fill: false) }

      vbuttonbox1.pack_start(vbuttonbox, expand: false, fill: false, padding: 10)
    end

    def set_buttons_leftside_signals
      gtk_window.signal_connect("destroy")      { save_preferences; quit }
      gtk_window.signal_connect("delete_event") { save_preferences; quit }
      buttons[0].signal_connect("activate")     { buttons[0].signal_emit("released") }
      buttons[0].signal_connect("released")     { save_preferences; show_disc_or_preferences }
      buttons[1].signal_connect("clicked")      { save_preferences; refresh_disc }
      buttons[2].signal_connect("clicked")      { save_preferences; handle_tray }
      buttons[3].signal_connect("clicked")      { save_preferences; start_rip }
      buttons[4].signal_connect("clicked")      { exit_button }
    end

    def exit_button
      if buttontext[4].text == _("Exit")
        save_preferences
        quit
      else
        Thread.new do
          rrip_redux.cancel_rip # Let rubyripper stop ripping and encoding
          @rrip_redux = nil # Kill the instance
          rrip_redux_thread.exit # Kill the thread
          buttons_sensitive!(true)
          change_display(gtk_disc)
        end
      end
    end

    def cancel_toc_scan
      `killall cdrdao 2>&1`
    end

    def save_preferences
      if current_instance == "GtkPreferences"
        buttontext[0].set_markup("_" + _("Preferences"), { use_underline: true })
        buttonicons[0].stock = gPREFERENCES
        gtk_prefs.save
      end
    end

    def quit
      `killall cdparanoia 2>&1`
      `killall cdrdao 2>&1`
      Gtk.main_quit
    end

    # Make sure the gtk preferences are loaded.
    #
    def startup_preferences
      if ! gtk_prefs
        @gtk_prefs = RripRedux::Gtk3::GtkPreferences.new
        gtk_prefs.start
      end
      gtk_prefs.display.page = 0
      change_display(gtk_prefs)
    end

    def refresh_disc
      cancel_toc_scan
      short_message.refresh_disc
      change_display(short_message)
      scan_disc
    end

    # Switch context between disc info and preferences.
    # The button should change to the opposite value.
    #
    def show_disc_or_preferences
      buttons_sensitive!(false)
      if current_instance != "GtkPreferences"
        buttontext[0].set_markup("_" + _("Disc info"), { use_underline: true })
        buttonicons[0].stock = gINFO
        startup_preferences
        buttons_sensitive!(true, 0, 1, 2, 4)
        buttons[3].sensitive = true if gtk_disc && gtk_disc.error.nil?
      elsif gtk_disc && gtk_disc.error.nil?
        change_display(gtk_disc)
        buttons_sensitive!(true)
      else
        refresh_disc
      end
    end

    def handle_tray
      buttons_sensitive!(false)
      if buttontext[2].text == _("Open tray")
        cancel_toc_scan
        open_drive
        ask_for_disc
      else
        close_drive
        scan_disc
      end
    end

    # Open the drive, so reset the gtk disc object.
    #
    def open_drive
      @gtk_disc = nil
      short_message.open_tray
      change_display(short_message)
      deps.eject(prefs.cdrom)
    end

    def show_closed_tray
      buttontext[2].set_markup("_" + _("Close tray"), { use_underline: true })
      buttonicons[2].stock = gGOTO_TOP
    end

    def show_open_tray
      buttontext[2].set_markup("_" + _("Open tray"), { use_underline: true })
      buttonicons[2].stock = gGOTO_BOTTOM
    end

    def ask_for_disc
      show_closed_tray
      short_message.ask_for_disc
      buttons_sensitive!(true, 0, 1, 2, 4)
    end

    def close_drive
      short_message.close_tray
      change_display(short_message)
      deps.close_tray(prefs.cdrom)
      show_open_tray
    end

    def start_rip
      buttons_sensitive!(false, 0, 1, 2, 3)
      gtk_disc.save

      @rrip_redux = RripReduxCore.new(self, gtk_disc.disc, gtk_disc.selection)

      errors = rrip_redux.check_configuration
      if errors.empty?
        update_interface_and_start_rip
      else
        buttons_sensitive!(true, 0, 1, 2, 3)
        show_errors(errors)
      end
    end

    def update_interface_and_start_rip
      buttons_sensitive!(false, 0, 1, 2, 3)
      @rip_status = RripRedux::Gtk3::RipStatus.new(self)
      change_display(rip_status)

      @rrip_redux_thread = Thread.new do
        rrip_redux.start_rip
      end
    end

    # Build the text then show the errors.
    #
    def show_errors(errors)
      text = +""
      text << _("Please solve the following configuration errors first:") + "\n"
      errors.each do |error|
        text << "  > " + Errors.send(error[0], error[1]) + "\n"
      end
      update("error", text)
    end

    def show_summary(success)
      buttons[0].sensitive = true
      buttons[1].sensitive = true if ! prefs.eject
      buttons[2].sensitive = true
      buttons[3].sensitive = true if ! prefs.eject

      @gtk_summary = RripRedux::Gtk3::GtkSummary.new(rrip_redux.file_scheme, rrip_redux.summary, success)
      change_display(gtk_summary)

      show_closed_tray if !! prefs.eject

      # Some resetting of variables, I suspect some optimization of ruby otherwise would prevent refreshing
      @rrip_redux = false
    end
  end
end
