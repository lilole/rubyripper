# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

module RripRedux
module Gtk3
  # The GtkDisc class shows the disc info.
  # This is placed in the frame of the main window beside the vertical buttonbox.
  #
  class GtkDisc
    include GetText; GetText.bindtextdomain("rrip_redux")
    include GtkConstants

    attr_reader :album_entry, :album_label, :all_tracks_button, :artist_entry, :artist_label, :check_track_array,
      :disc, :disc_info_table, :disc_number_label, :disc_number_spin, :display, :error, :firsttime, :frame10, :frame20,
      :freeze_checkbox, :genre_entry, :genre_label, :label10, :label20, :length_label, :length_label_array, :md,
      :scrolled_window, :selection, :track_entry_array, :track_info_table, :trackname_label, :ui,
      :var_artist_entry_array, :var_artist_label, :var_checkbox, :year_entry, :year_label

    def initialize(gui)
      @ui = gui
    end

    def start
      @firsttime = true
      refresh_disc
    end

    def refresh
      @firsttime = false
      refresh_disc
    end

    def refresh_gui
      build_disc_info unless disc_info_table
      build_track_info
      build_layout unless display
      update_disc(firsttime)
      update_tracks
    end

    # Store any updates the user has made and save the selected tracks.
    #
    def save
      # Compare user updates with existing metadata to detrmine if
      # freedb record needs to be saved into the local cache
      metadata = RripRedux::Metadata::Data.new
      update_metadata(metadata)
      no_user_changes = (metadata == md)

      # Now apply changes to real metadata
      update_metadata(md) unless no_user_changes

      # Update selection
      @selection = []
      (1..disc.audiotracks).each do |track|
        selection << track if check_track_array[track - 1].active?
      end

      # Trigger freedb record save to local cache
      disc.save unless no_user_changes
    end

  private

    def refresh_disc
      @selection = []
      @error = nil
      @disc = RripRedux::Disc::Disc.new
      Thread.new do
        disc.scan
        ui_update_msg = "scan_disc_finished"
        if disc.status == "ok"
          @md = disc.metadata
          ui_update_msg = "scan_disc_metadata_mutiple_records" if md.status == "multipleRecords"
        else
          @error = disc.error
        end
        ui.update(ui_update_msg)
      end
    end

    # Create all necessary objects for displaying the discinfo.
    #
    def build_disc_info
      set_disc_values
      config_disc_values
      set_disc_signals
      pack_disc_objects
    end

    # Create all necessary objects for displaying the trackselection.
    #
    def build_track_info
      set_track_info_table
      set_track_values
      config_track_values
      set_track_signals
      pack_track_objects
    end

    # Pack them together so we can show this beauty to the world :)
    #
    def build_layout
      set_display_values
      config_display_values
      pack_display_objects
    end

    def set_disc_values
      @disc_info_table = Gtk::Table.new(4, 4, false)

      @artist_label = Gtk::Label.new(_("Artist:"))
      @album_label  = Gtk::Label.new(_("Album:"))
      @genre_label  = Gtk::Label.new(_("Genre:"))
      @year_label   = Gtk::Label.new(_("Year:"))
      @var_checkbox = Gtk::CheckButton.new(_("Mark disc as various artist"))

      @freeze_checkbox   = Gtk::CheckButton.new(_("Freeze disc info"))
      @disc_number_label = Gtk::Label.new(_("Disc:"))
      @disc_number_spin  = Gtk::SpinButton.new(1.0, 99.0, 1.0)

      @artist_entry = Gtk::Entry.new
      @album_entry  = Gtk::Entry.new
      @genre_entry  = Gtk::Entry.new
      @year_entry   = Gtk::Entry.new
    end

    def config_disc_values
      disc_info_table.column_spacings = 5
      disc_info_table.row_spacings = 4
      disc_info_table.border_width = 7

      artist_label.set_alignment(0.0, 0.5)
      album_label.set_alignment(0.0, 0.5)
      genre_label.set_alignment(0.0, 0.5)
      year_label.set_alignment(0.0, 0.5)

      genre_entry.width_request = 100
      year_entry.width_request = 100

      freeze_checkbox.tooltip_text = _("Use this option to keep the disc info\nfor albums that span multiple discs")
      disc_number_label.set_alignment(0.0, 0.5)
      disc_number_label.sensitive = false
      disc_number_spin.value = 1.0
      disc_number_spin.sensitive = false
    end

    def set_disc_signals
      var_checkbox.signal_connect("toggled") do
        var_checkbox.active? ? set_var_artist : unset_var_artist
      end

      freeze_checkbox.signal_connect("toggled") do
        disc_number_label.sensitive = freeze_checkbox.active?
        disc_number_spin.sensitive  = freeze_checkbox.active?
      end
    end

    def pack_disc_objects
      disc_info_table.attach(artist_label,      0, 1, 0, 1, gFILL,         gSHRINK, 0, 0) # Column 1
      disc_info_table.attach(album_label,       0, 1, 1, 2, gFILL,         gSHRINK, 0, 0)
      disc_info_table.attach(artist_entry,      1, 2, 0, 1, gFILL|gEXPAND, gSHRINK, 0, 0) # Column 2
      disc_info_table.attach(album_entry,       1, 2, 1, 2, gFILL|gEXPAND, gSHRINK, 0, 0)
      disc_info_table.attach(genre_label,       2, 3, 0, 1, gFILL,         gSHRINK, 0, 0) # Column 3
      disc_info_table.attach(year_label,        2, 3, 1, 2, gFILL,         gSHRINK, 0, 0)
      disc_info_table.attach(genre_entry,       3, 4, 0, 1, gSHRINK,       gSHRINK, 0, 0) # Column 4
      disc_info_table.attach(year_entry,        3, 4, 1, 2, gSHRINK,       gSHRINK, 0, 0)
      disc_info_table.attach(var_checkbox,      0, 4, 3, 4, gFILL,         gSHRINK, 0, 0)
      disc_info_table.attach(freeze_checkbox,   0, 2, 2, 3, gFILL,         gSHRINK, 0, 0)
      disc_info_table.attach(disc_number_label, 2, 3, 2, 3, gFILL,         gSHRINK, 0, 0)
      disc_info_table.attach(disc_number_spin,  3, 4, 2, 3, gFILL,         gSHRINK, 0, 0)
    end

    def set_track_info_table
      if ! track_info_table
        @track_info_table = Gtk::Table.new(disc.audiotracks + 1, 4, false)
      else
        track_info_table.each { |child| track_info_table.remove(child) }
        track_info_table.resize(disc.audiotracks + 1, 4)
      end
    end

    def set_track_values
      @all_tracks_button = Gtk::CheckButton.new(_("All"))
      @var_artist_label = Gtk::Label.new(_("Artist"))
      @trackname_label = Gtk::Label.new(_("Track names \(%s track(s)\)") % [disc.audiotracks])
      @length_label = Gtk::Label.new(_("Length \(%s\)") % [disc.playtime])

      @check_track_array = []
      @var_artist_entry_array = []
      @track_entry_array = []
      @length_label_array = []

      (1..disc.audiotracks).each do |track|
        @check_track_array << Gtk::CheckButton.new(track.to_s)
        @var_artist_entry_array << Gtk::Entry.new
        @track_entry_array << Gtk::Entry.new
        @length_label_array << Gtk::Label.new(disc.get_length_text(track))
      end
    end

    def config_track_values
      track_info_table.column_spacings = 5
      track_info_table.row_spacings = 4
      track_info_table.border_width = 7

      all_tracks_button.active = true
      check_track_array.each { |checkbox| checkbox.active = true }
    end

    def set_track_signals
      all_tracks_button.signal_connect("toggled") do
        # Signal to toggle on/off all tracks
        state = !! all_tracks_button.active?
        check_track_array.each { |box| box.active = state }
      end
    end

    # Pack with or without support for various artists.
    #
    def pack_track_objects
      track_info_table.attach(all_tracks_button, 0, 1, 0, 1, gFILL, gSHRINK, 0, 0) # R 1 C 1
      track_info_table.attach(length_label,      3, 4, 0, 1, gFILL, gSHRINK, 0, 0) # R 1 C 4

      if md.various?
        track_info_table.attach(var_artist_label, 1, 2, 0, 1, gFILL, gSHRINK, 0, 0) # R 1 C 2
        track_info_table.attach(trackname_label,  2, 3, 0, 1, gFILL, gSHRINK, 0, 0) # R 1 C 3
      else
        track_info_table.attach(trackname_label, 1, 3, 0, 1, gFILL|gEXPAND, gSHRINK, 0, 0)
      end

      disc.audiotracks.times do |index|
        track_info_table.attach(check_track_array[index],  0, 1, 1 + index, 2 + index, gFILL, gSHRINK, 0, 0) # R 2 C 1
        track_info_table.attach(length_label_array[index], 3, 4, 1 + index, 2 + index, gFILL, gSHRINK, 0, 0) # R 2 C 4

        if md.various?
          track_info_table.attach(var_artist_entry_array[index], 1, 2, index + 1, index + 2, gFILL, gSHRINK, 0, 0)
          track_info_table.attach(track_entry_array[index],      2, 3, index + 1, index + 2, gFILL, gSHRINK, 0, 0)
        else
          track_info_table.attach(track_entry_array[index], 1, 3, 1 + index, 2 + index, gFILL|gEXPAND, gSHRINK, 0, 0) # R 2 C 2+3
        end
      end
    end

    def set_display_values
      @label10 = Gtk::Label.new
      @frame10 = Gtk::Frame.new

      @scrolled_window = Gtk::ScrolledWindow.new

      @label20 = Gtk::Label.new
      @frame20 = Gtk::Frame.new

      @display = Gtk::Box.new(:vertical) # One VBox to rule them all
    end

    def config_display_values
      label10.set_markup(_("<b>Disc info</b>"))
      frame10.set_shadow_type(gETCHED_IN)
      frame10.label_widget = label10
      frame10.border_width = 5

      scrolled_window.set_policy(gAUTOMATIC, gAUTOMATIC)
      scrolled_window.set_border_width(5)

      label20.set_markup(_("<b>Track selection</b>"))
      frame20.set_shadow_type(gETCHED_IN)
      frame20.label_widget = label20
      frame20.border_width = 5
    end

    def pack_display_objects
      frame10.add(disc_info_table)

      scrolled_window.add_with_viewport(track_info_table)
      frame20.add(scrolled_window)
      track_info_table.focus_vadjustment = scrolled_window.vadjustment

      display.pack_start(frame10, expand: false, fill: false)
      display.pack_start(frame20, expand: true, fill: true)
    end

    def update_disc(firsttime=false)
      if !! freeze_checkbox.active?
        artist_entry.text = md.artist
        album_entry.text  = md.album
        genre_entry.text  = md.genre
        year_entry.text   = md.year
      else
        disc_number_spin.value += 1.0 unless firsttime
      end

      var_checkbox.active = !! md.various?
    end

    def update_tracks
      (1..disc.audiotracks).each do |track|
        track_entry_array[track - 1].text = md.trackname(track)
      end
      set_var_artist if md.various?
      track_info_table.show_all
    end

    def update_metadata(metadata)
      metadata.artist      = artist_entry.text
      metadata.album       = album_entry.text
      metadata.genre       = genre_entry.text
      metadata.year        = year_entry.text if year_entry.text.to_i != 0
      metadata.disc_number = disc_number_spin.value.to_i if freeze_checkbox.active?
      metadata.discid      = disc.freedb_discid

      (1..disc.audiotracks).each do |track|
        metadata.set_trackname(track, track_entry_array[track - 1].text)
        metadata.set_var_artist(track, var_artist_entry_array[track - 1].text) if md.various?
      end
    end

    # Update the view for various artists.
    #
    def set_var_artist
      md.mark_var_artist
      disc.audiotracks.times { |index| var_artist_entry_array[index].text = md.get_var_artist(index + 1) }
      disc.audiotracks.times { |index| track_entry_array[index].text = md.trackname(index + 1) }
      update_tracks_view
    end

    # Update the view for normal artists.
    #
    def unset_var_artist
      md.unmark_var_artist
      disc.audiotracks.times { |index| track_entry_array[index].text = md.trackname(index + 1) }
      update_tracks_view
    end

    # Remove current objects and repackage the view.
    #
    def update_tracks_view
      track_info_table.each { |child| track_info_table.remove(child) }
      pack_track_objects
      track_info_table.show_all
    end
  end
end
end
