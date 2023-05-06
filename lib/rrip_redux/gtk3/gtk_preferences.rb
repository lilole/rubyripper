# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

module RripRedux
module Gtk3
  # The class GtkPreferences allows the user to change his preferences.
  # This class is responsible for building the frame on the right side.
  #
  class GtkPreferences
    include GetText; GetText.bindtextdomain("rrip_redux")

    DEFAULT_COLUMN_SPACINGS = 5
    DEFAULT_ROW_SPACINGS = 4
    DEFAULT_BORDER_WIDTH = 7

    attr_reader :add_codec_button, :add_codec_combo_box, :add_codec_label,
      :all_chunks, :all_chunks_spin, :append_pregaps,
      :basedir_entry, :basedir_label,
      :cdrdao, :cdrdao_hbox, :cdrdao_image,
      :cdrom_entry, :cdrom_label, :cdrom_offset_label, :cdrom_offset_spin,
      :choose_latest_release, :choose_original_release, :choose_original_year, :choose_release_year,
      :codec_labels, :codec_rows,
      :correct_pre_emphasis, :create_cuesheet, :debug, :deps, :display, :do_not_correct_pre_emphasis,
      :editor_entry, :editor_label,
      :eject, :entry_preferred_country,
      :err_chunks, :err_chunks_spin,
      :example_label, :example_label_shows,
      :expander100,
      :filemanager_entry, :filemanager_label,
      :first_hit,
      :frame40, :frame50, :frame60, :frame70, :frame80, :frame85, :frame90, :frame91, :frame92, :frame100, :frame110, :frame120,
      :frame_toc1, :frame_toc2, :frame_toc3, :frame_toc4,
      :freedb_hostname_entry, :freedb_hostname_label, :freedb_server_entry, :freedb_server_label,
      :freedb_username_entry, :freedb_username_label,
      :image,
      :label_preferred_country, :label_preferred_release, :label_preferred_year,
      :legend_label,
      :mark_hidden_track_label1, :mark_hidden_track_label2,
      :max_label, :max_spin, :max_threads, :max_threads_label,
      :metadata_choice, :metadata_label,
      :min_length_hidden_track_spin, :modus,
      :naming_image_entry, :naming_image_label, :naming_normal_entry, :naming_normal_label,
      :naming_various_entry, :naming_various_label,
      :no_capitals, :no_log, :no_spaces, :normalize, :offset_button, :pad_missing_samples,
      :page1, :page1_label, :page2, :page2_label, :page3, :page3_label, :page4, :page4_label, :page_toc, :page_toc_label,
      :playlist, :prefs, :prepend_pregaps,
      :rip_entry, :rip_hidden_audio, :rip_label,
      :select_codecs_table,
      :table40, :table50, :table60, :table80, :table85, :table90, :table91, :table92, :table100, :table110, :table120,
      :table_toc1, :table_toc2, :table_toc3, :table_toc4,
      :time1, :time2, :time3,
      :vbox_toc, :verbose

    def initialize(prefs=nil, deps=nil)
      @prefs        = prefs || RripRedux::Preferences::Main.instance
      @deps         = deps || RripRedux::System::Dependency.instance
      @codec_labels = {
        "flac" => "FLAC", "fraunhofer" => "Fraunhofer AAC", "nero" => "Nero AAC",
        "other" => _("Other"), "wavpack" => "WavPack"
      }
    end

    def start
      @display = Gtk::Notebook.new
      build_secure_ripping_tab
      build_toc_analysis_tab
      build_codecs_tab
      build_metadata_tab
      build_other_tab
      load_preferences
    end

    def save
      save_preferences
    end

  private

    # Tab 1
    def build_secure_ripping_tab
      build_frame_cdrom_device
      build_frame_ripping_options
      build_frame_ripping_related
    end

    # Tab 2
    def build_toc_analysis_tab
      build_frame_audio_sectors_before_track_one
      build_frame_advanced_toc_analysis
      build_frame_handling_pregaps_other_than_track_one
      build_frame_handling_tracks_with_pre_emphasis
    end

    # Tab 3
    def build_codecs_tab
      build_frame_select_audio_codecs
      build_frame_codec_related
      build_frame_normalize_to_standard_volume
    end

    # Tab 4
    def build_metadata_tab
      build_frame_choose_metadata_provider
      build_frame_freedb_options
      build_frame_musicbrainz_options
      pack_metadata_frames
    end

    # Tab 5
    def build_other_tab
      build_frame_filenaming_scheme
      build_frame_programs_of_choice
      build_frame_debug_options
      pack_other_frames
    end

    # Fill all objects with the right value.
    #
    def load_preferences
     # Ripping settings
      cdrom_entry.text           = prefs.cdrom
      cdrom_offset_spin.value    = prefs.offset.to_f
      pad_missing_samples.active = prefs.pad_missing_samples
      all_chunks_spin.value      = prefs.req_matches_all.to_f
      err_chunks_spin.value      = prefs.req_matches_errors.to_f
      max_spin.value             = prefs.max_tries.to_f
      rip_entry.text             = prefs.rippersettings
      eject.active               = prefs.eject
      no_log.active              = prefs.no_log

      # Toc settings
      create_cue.active                  = prefs.create_cue
      image.active                       = prefs.image
      rip_hidden_audio.active            = prefs.rip_hidden_audio
      min_length_hidden_track_spin.value = prefs.min_length_hidden_track.to_f
      append_pregaps.active              = prefs.pre_gaps == "append"
      prepend_pregaps.active             = prefs.pre_gaps == "prepend"
      correct_pre_emphasis.active        = prefs.pre_emphasis == "sox"
      do_not_correct_pre_emphasis.active = prefs.pre_emphasis == "cue"

      # Codec settings (actual codecs are loaded when the objects are created)
      playlist.active    = prefs.playlist
      no_spaces.active   = prefs.no_spaces
      no_capitals.active = prefs.no_capitals
      max_threads.value  = prefs.max_threads.to_f
      normalize.active   = load_normalizer
      modus.active       = prefs.gain == "album" ? 0 : 1

      # Metadata
      metadata_choice.active         = load_metadata_provider
      first_hit.active               = prefs.first_hit
      freedb_server_entry.text       = prefs.site
      freedb_username_entry.text     = prefs.username
      freedb_hostname_entry.text     = prefs.hostname
      entry_preferred_country.text   = prefs.prefer_music_brainz_countries
      choose_original_release.active = prefs.prefer_music_brainz_date == "earlier"
      choose_latest_release.active   = prefs.prefer_music_brainz_date == "later"
      choose_original_year.active    = prefs.use_earliest_date
      choose_release_year.active     = ! prefs.use_earliest_date

      # Other
      basedir_entry.text        = prefs.basedir
      naming_normal_entry.text  = prefs.naming_normal
      naming_various_entry.text = prefs.naming_various
      naming_image_entry.text   = prefs.naming_image
      verbose.active            = prefs.verbose
      debug.active              = prefs.debug
      editor_entry.text         = prefs.editor
      filemanager_entry.text    = prefs.filemanager
    end

    def load_normalizer
      case prefs.normalizer
      when "none"       then 0
      when "replaygain" then 1
      when "normalize"  then 2
      end
    end

    def load_metadata_provider
      case prefs.metadata_provider
      when "freedb"      then 0
      when "gnudb"       then 0
      when "musicbrainz" then 1
      when "none"        then 2
      end
    end

    # Update the preferences object with latest values.
    #
    def save_preferences
      # Ripping settings
      prefs.cdrom               = cdrom_entry.text
      prefs.offset              = cdrom_offset_spin.value.to_i
      prefs.pad_missing_samples = pad_missing_samples.active?
      prefs.req_matches_all     = all_chunks_spin.value.to_i
      prefs.req_matches_errors  = err_chunks_spin.value.to_i
      prefs.max_tries           = max_spin.value.to_i
      prefs.rippersettings      = rip_entry.text
      prefs.eject               = eject.active?
      prefs.no_log              = no_log.active?

      # Toc settings
      prefs.create_cue              = create_cue.active?
      prefs.image                   = image.active?
      prefs.rip_hidden_audio        = rip_hidden_audio.active?
      prefs.min_length_hidden_track = min_length_hidden_track_spin.value.to_i
      prefs.pre_gaps                = append_pregaps.active? ? "append" : "prepend"
      prefs.pre_emphasis            = correct_pre_emphasis.active? ? "sox" : "cue"

      # Codec settings
      codec_rows.each do |label, objects|
        prefs.send(:"#{get_codec_for_label(label)}=", true)
        prefs.send(:"settings_#{get_codec_for_label(label)}=", objects[1].text)
      end
      prefs.playlist    = playlist.active?
      prefs.no_spaces   = no_spaces.active?
      prefs.no_capitals = no_capitals.active?
      prefs.max_threads = max_threads.value.to_i
      prefs.normalizer  = save_normalizer
      prefs.gain        = modus.active == 0 ? "album" : "track"

      # Metadata
      prefs.metadata_provider             = save_metadata_provider
      prefs.first_hit                     = first_hit.active?
      prefs.site                          = freedb_server_entry.text
      prefs.username                      = freedb_username_entry.text
      prefs.hostname                      = freedb_hostname_entry.text
      prefs.prefer_music_brainz_countries = entry_preferred_country.text
      prefs.prefer_music_brainz_date      = choose_original_release.active? ? "earlier" : "later"
      prefs.use_earliest_date             = choose_original_year.active?

      # Other
      prefs.basedir        = basedir_entry.text
      prefs.naming_normal  = naming_normal_entry.text
      prefs.naming_various = naming_various_entry.text
      prefs.naming_image   = naming_image_entry.text
      prefs.verbose        = verbose.active?
      prefs.debug          = debug.active?
      prefs.editor         = editor_entry.text
      prefs.filemanager    = filemanager_entry.text
      prefs.save # Also updates the config file
    end

    def save_normalizer
      case normalize.active
      when 0 then "none"
      when 1 then "replaygain"
      when 2 then "normalize"
      end
    end

    def save_metadata_provider
      case metadata_choice.active
      when 0 then "gnudb"
      when 1 then "musicbrainz"
      when 2 then "none"
      end
    end

    # Helper to create a table.
    #
    def new_table(rows0=nil, columns0=nil, homogeneous=false, rows: nil, columns: nil)
      rows ||= rows0
      columns ||= columns0
      Gtk::Table.new(rows, columns, homogeneous).tap do |t|
        t.column_spacings = DEFAULT_COLUMN_SPACINGS
        t.row_spacings    = DEFAULT_ROW_SPACINGS
        t.border_width    = DEFAULT_BORDER_WIDTH
      end
    end

    # Helper to create a frame.
    #
    def new_frame(label0=nil, child0=nil, label: nil, child: nil)
      label ||= label0
      child ||= child0
      Gtk::Frame.new(label).tap do |f|
        f.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
        f.border_width = DEFAULT_BORDER_WIDTH
        f.add(child)
      end
    end

    # Secure ripping tab, frame 1
    def build_frame_cdrom_device
      @table40 = new_table(rows: 3, columns: 3)

      # Creating objects
      @cdrom_label        = Gtk::Label.new(_("Cdrom device:")); cdrom_label.set_alignment(0.0, 0.5) # Align to the left
      @cdrom_offset_label = Gtk::Label.new(_("Cdrom offset:")); cdrom_offset_label.set_alignment(0.0, 0.5)
      @cdrom_entry        = Gtk::Entry.new; cdrom_entry.width_request = 120
      @cdrom_offset_spin  = Gtk::SpinButton.new(-1500.0, 1500.0, 1.0); cdrom_offset_spin.value = 0.0

      @offset_button = Gtk::LinkButton.new(_("List with offsets"))
      offset_button.uri = "http://www.accuraterip.com/driveoffsets.htm"
      offset_button.tooltip_text = _("A website which lists the offset for most drives.\n" \
        "Your drivename can be found in each logfile.")

      # Pack objects
      @pad_missing_samples = Gtk::CheckButton.new(_("Pad missing samples with zero's"))
      pad_missing_samples.tooltip_text = _("Cdparanoia can't handle offsets larger than 580 for\n" \
        "first (negative offset) and last (positive offset) track.\n" \
        "This option fills the rest with empty samples.\n" \
        "If disabled, the file will not have the correct size.\n" \
        "It is recommended to enable this option.")
      pad_missing_samples.sensitive = false

      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table40.attach(cdrom_label,         0, 1, 0, 1, fill,   shrink, 0, 0)
      table40.attach(cdrom_offset_label,  0, 1, 1, 2, fill,   shrink, 0, 0)
      table40.attach(cdrom_entry,         1, 2, 0, 1, shrink, shrink, 0, 0)
      table40.attach(cdrom_offset_spin,   1, 2, 1, 2, fill,   shrink, 0, 0)
      table40.attach(offset_button,       2, 3, 1, 2, fill,   shrink, 0, 0)
      table40.attach(pad_missing_samples, 0, 2, 2, 3, fill,   shrink, 0, 0)

      # Connect signals
      offset_button.signal_connect("clicked") do
        Thread.new { `#{prefs.browser} #{offset_button.uri} 2>&1` }
      end
      cdrom_offset_spin.signal_connect("value-changed") { enable_padding_option }

      @frame40 = new_frame(_("Cdrom device"), table40)
    end

    def enable_padding_option
      value = cdrom_offset_spin.value.to_i
      pad_missing_samples.sensitive = (value > 580 || value < -580)
    end

    # Secure ripping tab, frame 2.
    #
    def build_frame_ripping_options
      @table50 = new_table(rows: 3, columns: 3)

      # Create objects
      @all_chunks      = Gtk::Label.new(_("Match all chunks:")); all_chunks.set_alignment(0.0, 0.5)
      @err_chunks      = Gtk::Label.new(_("Match erroneous chunks:")); err_chunks.set_alignment(0.0, 0.5)
      @max_label       = Gtk::Label.new(_("Maximum trials (0 = unlimited):")); max_label.set_alignment(0.0, 0.5)
      @all_chunks_spin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
      @err_chunks_spin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
      @max_spin        = Gtk::SpinButton.new(0.0, 100.0, 1.0)
      @time1           = Gtk::Label.new(_("times"))
      @time2           = Gtk::Label.new(_("times"))
      @time3           = Gtk::Label.new(_("times"))

      # Pack objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table50.attach(all_chunks,      0, 1, 0, 1, fill, shrink, 0, 0) # Col 1
      table50.attach(err_chunks,      0, 1, 1, 2, fill, shrink, 0, 0)
      table50.attach(max_label,       0, 1, 2, 3, fill, shrink, 0, 0)
      table50.attach(all_chunks_spin, 1, 2, 0, 1, fill, shrink, 0, 0) # Col 2
      table50.attach(err_chunks_spin, 1, 2, 1, 2, fill, shrink, 0, 0)
      table50.attach(max_spin,        1, 2, 2, 3, fill, shrink, 0, 0)
      table50.attach(time1,           2, 3, 0, 1, fill, shrink, 0, 0) # Col 3
      table50.attach(time2,           2, 3, 1, 2, fill, shrink, 0, 0)
      table50.attach(time3,           2, 3, 2, 3, fill, shrink, 0, 0)

      # Connect a signal to all_chunks to make sure err_chunks always get at least the same amount of rips as all_chunks
      all_chunks_spin.signal_connect("value_changed") do
        # Ensure all_chunks cannot be smaller than err_chunks
        if err_chunks_spin.value < all_chunks_spin.value
          err_chunks_spin.value = all_chunks_spin.value
        end
        err_chunks_spin.set_range(all_chunks_spin.value, 100.0)
      end

      @frame50 = new_frame(_("Ripping options"), table50)
    end

    def build_frame_ripping_related
      @table60 = new_table(rows: 2, columns: 3)

      # Create objects
      @rip_label = Gtk::Label.new(_("Pass cdparanoia options:")); rip_label.set_alignment(0.0, 0.5)
      @eject     = Gtk::CheckButton.new(_("Eject cd when finished"))
      @no_log    = Gtk::CheckButton.new(_("Only keep logfile if correction is needed"))
      @rip_entry = Gtk::Entry.new; rip_entry.width_request = 120

      # Pack objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table60.attach(rip_label, 0, 1, 0, 1, fill,          shrink, 0, 0)
      table60.attach(rip_entry, 1, 2, 0, 1, shrink,        shrink, 0, 0)
      table60.attach(eject,     0, 2, 1, 2, fill,          shrink, 0, 0)
      table60.attach(no_log,    0, 2, 2, 3, fill | shrink, shrink, 0, 0)

      @frame60 = new_frame(_("Ripping related"), table60)

      # Pack all frames into a single page
      @page1       = Gtk::Box.new(:vertical) # One VBox to rule them all
      @page1_label = Gtk::Label.new(_("Secure Ripping"))
      [frame40, frame50, frame60].each { |frame| page1.pack_start(frame, expand: false, fill: false) }

      display.append_page(page1, page1_label)
    end

    def build_frame_audio_sectors_before_track_one
      # Create objects
      @table_toc1                   = new_table(rows: 3, columns: 3)
      @rip_hidden_audio             = Gtk::CheckButton.new(_("Rip hidden audio sectors"))
      @mark_hidden_track_label1     = Gtk::Label.new(_("Mark as a hidden track when longer than"))
      @mark_hidden_track_label2     = Gtk::Label.new(_("second(s)"))
      @min_length_hidden_track_spin = Gtk::SpinButton.new(0, 30, 1)

      min_length_hidden_track_spin.value = 2.0
      rip_hidden_audio.tooltip_text = _("Uncheck this if cdparanoia crashes with your ripping drive.")
      text = _("A hidden track will rip to a seperate file if used in track mode.\n" \
        "If it's smaller the sectors will be prepended to the first track.")
      min_length_hidden_track_spin.tooltip_text = text
      mark_hidden_track_label1.tooltip_text = text
      mark_hidden_track_label2.tooltip_text = text

      # Pack objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table_toc1.attach(rip_hidden_audio,             0, 1, 0, 1, fill, shrink, 0, 0)
      table_toc1.attach(mark_hidden_track_label1,     0, 1, 1, 2, fill, shrink, 0, 0)
      table_toc1.attach(min_length_hidden_track_spin, 1, 2, 1, 2, fill, shrink, 0, 0)
      table_toc1.attach(mark_hidden_track_label2,     2, 3, 1, 2, fill, shrink, 0, 0)

      rip_hidden_audio.signal_connect("clicked") do
        min_length_hidden_track_spin.sensitive = rip_hidden_audio.active?
      end

      @frame_toc1 = new_frame(_("Audio sectors before track 1"), table_toc1)
    end

    def build_frame_advanced_toc_analysis
      # Create objects
      @table_toc2      = new_table(rows: 3, columns: 2)
      @create_cuesheet = Gtk::CheckButton.new(_("Create cuesheet"))
      @image           = Gtk::CheckButton.new(_("Rip CD to single file"))

      # Pack objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table_toc2.attach(create_cue, 0, 2, 1, 2, fill,          shrink, 0, 0)
      table_toc2.attach(image,      0, 2, 2, 3, fill | shrink, shrink, 0, 0)

      @vbox_toc = Gtk::Box.new(:vertical)
      vbox_toc.pack_start(table_toc2, expand: false, fill: false)

      @frame_toc2 = new_frame(_("Advanced Toc analysis"), vbox_toc)

      # Hbox for cdrdao
      @cdrdao_hbox  = Gtk::Box.new(:horizontal, 5)
      @cdrdao       = Gtk::Label.new(_("Cdrdao installed?"))
      @cdrdao_image = Gtk::Image.new(stock: Gtk::Stock::CANCEL, size: Gtk::IconSize::BUTTON)
      cdrdao_hbox.pack_start(cdrdao, expand: false, fill: false, padding: 5)
      cdrdao_hbox.pack_start(cdrdao_image, expand: false, fill: false)
    end

    def build_frame_handling_pregaps_other_than_track_one
      # Create objects
      @table_toc3      = new_table(rows: 3, columns: 3)
      @append_pregaps  = Gtk::RadioButton.new(label: _("Append pregap to the previous track"))
      @prepend_pregaps = Gtk::RadioButton.new(member: append_pregaps, label: _("Prepend pregap to the track"))

      # Pack objects
      table_toc3.attach(append_pregaps,  0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table_toc3.attach(prepend_pregaps, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)

      @frame_toc3 = new_frame(_("Handling pregaps other than track 1"), table_toc3)

      vbox_toc.pack_start(frame_toc3, expand: false, fill: false)
    end

    def build_frame_handling_tracks_with_pre_emphasis
      @table_toc4 = new_table(rows: 3, columns: 3)

      # Create objects
      @correct_pre_emphasis = Gtk::RadioButton.new(label: _("Correct pre-emphasis tracks with sox"))
      @do_not_correct_pre_emphasis = Gtk::RadioButton.new(
        member: correct_pre_emphasis,
        label: _("Save the pre-emphasis tag in the cuesheet.")
      )
      # Pack objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table_toc4.attach(correct_pre_emphasis,        0, 1, 0, 1, fill, shrink, 0, 0)
      table_toc4.attach(do_not_correct_pre_emphasis, 0, 1, 1, 2, fill, shrink, 0, 0)

      @frame_toc4 = new_frame(_("Handling tracks with pre-emphasis"), table_toc4)

      vbox_toc.pack_start(frame_toc4, expand: false, fill: false)

      # Pack all frames into a single page
      set_signals_toc
      @page_toc = Gtk::Box.new(:vertical) # One VBox to rule them all
      @page_toc_label = Gtk::Label.new(_("TOC analysis"))
      [frame_toc1, cdrdao_hbox, frame_toc2].each { |frame| page_toc.pack_start(frame, expand: false, fill: false) }

      display.append_page(page_toc, page_toc_label)
    end

    def cdrdao_installed
      if deps.installed?("cdrdao")
        cdrdao_image.stock = Gtk::Stock::APPLY
        frame_toc2.each { |child| child.sensitive = true }
      else
        cdrdao_image.stock = Gtk::Stock::CANCEL
        create_cue.active = false
        frame_toc2.each { |child| child.sensitive = false }
      end
    end

    def create_cue
      active = !! create_cuesheet.active?
      image.sensitive = active
      image.active    = active
      table_toc3.each { |child| child.sensitive = active }
      table_toc4.each { |child| child.sensitive = active }
    end

    def create_single
      table_toc3.each { |child| child.sensitive = ! image.active? }
      correct_pre_emphasis.active = true
      do_not_correct_pre_emphasis.sensitive = ! image.active?
    end

    def set_signals_toc
      cdrdao_installed
      create_single
      create_cue

      create_cuesheet.signal_connect("clicked") do
        create_cue
        `killall cdrdao 2>&1` if ! create_cue.active?
      end

      image.signal_connect("clicked") { create_single }
    end

    def build_frame_select_audio_codecs
      @codec_rows = Hash.new
      prefs.codecs.each { |codec| create_codec_row(codec) }
      @select_codecs_table = new_table(rows: codec_rows.size + 1, columns: 3)
      create_codecs_table
      @frame70 = new_frame(_("Active audio codecs"), select_codecs_table)
    end

    def create_codec_row(codec)
      codec_rows[codec] = [Gtk::Label.new(get_label_for_codec(codec))]
      codec_rows[codec][0].set_alignment(0, 0.5)
      if codec == "wav"
        codec_rows[codec] << Gtk::Label.new(_("No settings available"))
        codec_rows[codec][1].set_alignment(0, 0.5)
      else
        codec_rows[codec] << Gtk::Entry.new()
        codec_rows[codec][1].text = prefs.send(:"settings_#{codec}")
      end
      codec_rows[codec] << Gtk::Button.new(stock_id: Gtk::Stock::REMOVE)

      add_tooltip_for_other_codec(codec_rows[codec][1]) if codec == "other"

      # Connect the remove button signal
      codec_rows[codec][2].signal_connect("button_release_event") do |a, b|
        codec_rows[codec].each { |object| select_codecs_table.remove(object) }
        codec_rows.delete(codec)
        prefs.send(:"#{codec}=", false)
        update_codecs_view
      end
    end

    def get_label_for_codec(codec)
      codec_labels.key?(codec) ? codec_labels[codec] : codec.capitalize
    end

    def get_codec_for_label(label)
      codec_labels.value?(label) ? codec_labels.key(label) : label.downcase
    end

    def update_codecs_view
      select_codecs_table.each { |child| select_codecs_table.remove(child) }
      select_codecs_table.resize(rows: codec_rows.size + 1, columns: 3)
      create_codecs_table
      select_codecs_table.show_all
    end

    def create_codecs_table
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      expand = Gtk::AttachOptions::EXPAND
      top = 0
      codec_rows.each do |codec, row|
        select_codecs_table.attach(row[0], 0, 1, top, top + 1, fill,        shrink, 0, 0)
        select_codecs_table.attach(row[1], 1, 2, top, top + 1, fill|expand, shrink, 0, 0)
        select_codecs_table.attach(row[2], 2, 3, top, top + 1, fill,        shrink, 0, 0)
        top += 1
      end

      create_add_codec_row
    end

    def add_tooltip_for_other_codec(entry)
      entry.tooltip_text = _(
        "%a=artist %g=genre %t=track name %f=codec %b=album\n" \
        "  %y=year %n=track %va=various artist %o=output file %i=input file"
      )
    end

    def create_add_codec_row
      @add_codec_combo_box = Gtk::ComboBoxText.new
      prefs.all_codecs.each do |codec|
        add_codec_combo_box.append_text(get_label_for_codec(codec)) if ! codec_rows.key?(codec)
      end

      if add_codec_label.nil?
        @add_codec_label = Gtk::Label.new(_("Codec"))
        add_codec_label.set_alignment(0, 0.5)
        @add_codec_button = Gtk::Button.new(stock_id: Gtk::Stock::ADD)

        # Create the signal for the button
        add_codec_button.signal_connect("button_release_event") do |a, b|
          label = add_codec_combo_box.active_text
          if label && ! label.strip.empty?
            create_codec_row(get_codec_for_label(label.strip))
            update_codecs_view
          end
        end
      end

      # Put the row into the table
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      expand = Gtk::AttachOptions::EXPAND
      top = codec_rows.size
      select_codecs_table.attach(add_codec_label,     0, 1, top, top + 1, fill,        shrink, 0, 0)
      select_codecs_table.attach(add_codec_combo_box, 1, 2, top, top + 1, fill|expand, shrink, 0, 0)
      select_codecs_table.attach(add_codec_button,    2, 3, top, top + 1, fill,        shrink, 0, 0)
    end

    def build_frame_codec_related
      @table80 = new_table(rows: 2, columns: 2)

      # Creating objects
      @playlist          = Gtk::CheckButton.new(_("Create m3u playlist"))
      @max_threads       = Gtk::SpinButton.new(0.0, 10.0, 1.0)
      @max_threads_label = Gtk::Label.new(_("Number of extra encoding threads"))

      # Packing objects
      table80.attach(max_threads_label, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      table80.attach(max_threads,       1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      table80.attach(playlist,          0, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @frame80 = new_frame(_("Codec related"), table80)
    end

    def build_frame_normalize_to_standard_volume
      @table85 = new_table(rows: 2, columns: 1)

      # Creating objects
      @normalize = Gtk::ComboBoxText.new
      normalize.append_text(_("Don't standardize volume"))
      normalize.append_text(_("Use replaygain on audio files"))
      normalize.append_text(_("Use normalize on WAVE files"))
      normalize.active = 0

      @modus = Gtk::ComboBoxText.new
      modus.append_text(_("Album / Audiophile modus"))
      modus.append_text(_("Track modus"))
      modus.active = 0
      modus.sensitive = false

      normalize.signal_connect("changed") { modus.sensitive = (normalize.active != 0) }

      # Packing objects
      table85.attach(normalize, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      table85.attach(modus,     1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @frame85 = new_frame(_("Normalize to standard volume"), table85)

      # Pack all frames into a single page
      @page2 = Gtk::Box.new(:vertical) # One VBox to rule them all
      [frame70, frame80, frame85].each { |frame| page2.pack_start(frame, expand: false, fill: false) }
      @page2_label = Gtk::Label.new(_("Codecs"))
      display.append_page(page2, page2_label)
    end

    def build_frame_choose_metadata_provider
      @table90 = new_table(rows: 1, columns: 2)
      @metadata_label = Gtk::Label.new(_("Primary metadata provider:"))
      @metadata_choice = Gtk::ComboBoxText.new()

      metadata_choice.append_text(_("Gnudb"))
      metadata_choice.append_text(_("Musicbrainz"))
      metadata_choice.append_text(_("Don't use a metadata provider"))

      table90.attach(metadata_label,  0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table90.attach(metadata_choice, 1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)

      @frame90 = new_frame(_("Choose your metadata provider"), table90)
    end

    def build_frame_freedb_options
      @table91 = new_table(rows: 4, columns: 2)

      # Creating objects
      @first_hit             = Gtk::CheckButton.new(_("Always use first gnudb hit"))
      @freedb_server_label   = Gtk::Label.new(_("Gnudb server:")); freedb_server_label.set_alignment(0.0, 0.5)
      @freedb_username_label = Gtk::Label.new(_("Username:"));     freedb_username_label.set_alignment(0.0, 0.5)
      @freedb_hostname_label = Gtk::Label.new(_("Hostname:"));     freedb_hostname_label.set_alignment(0.0, 0.5)
      @freedb_server_entry   = Gtk::Entry.new
      @freedb_username_entry = Gtk::Entry.new
      @freedb_hostname_entry = Gtk::Entry.new

      # Packing objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      expand = Gtk::AttachOptions::EXPAND
      table91.attach(first_hit,             0, 2, 0, 1, fill,        shrink, 0, 0) # Both cols, 2nd row
      table91.attach(freedb_server_label,   0, 1, 1, 2, fill,        shrink, 0, 0) # 1st col, 3rd row
      table91.attach(freedb_username_label, 0, 1, 2, 3, fill,        shrink, 0, 0) # 1st col, 4th row
      table91.attach(freedb_hostname_label, 0, 1, 3, 4, fill,        shrink, 0, 0) # 1st col, 5th row
      table91.attach(freedb_server_entry,   1, 2, 1, 2, fill|expand, shrink, 0, 0) # 2nd col, 3rd row
      table91.attach(freedb_username_entry, 1, 2, 2, 3, fill|expand, shrink, 0, 0) # 2nd col, 4th row
      table91.attach(freedb_hostname_entry, 1, 2, 3, 4, fill|expand, shrink, 0, 0) # 2nd col, 5th row

      @frame91 = new_frame(_("Gnudb options"), table91)
    end

    def build_frame_musicbrainz_options
      @table92 = new_table(rows: 3, columns: 3)

      @label_preferred_country = Gtk::Label.new(_("Preferred countries:")); label_preferred_country.set_alignment(0.0, 0.5)
      @entry_preferred_country = Gtk::Entry.new

      @label_preferred_release = Gtk::Label.new(_("Preferred release date:")); label_preferred_release.set_alignment(0.0, 0.5)
      @choose_original_release = Gtk::RadioButton.new(label: _("Original"))
      @choose_latest_release   = Gtk::RadioButton.new(member: choose_original_release, label: _("Latest available"))

      @label_preferred_year = Gtk::Label.new(_("Preferred year (metadata):")); label_preferred_year.set_alignment(0.0, 0.5)
      @choose_original_year = Gtk::RadioButton.new(label: _("Original"))
      @choose_release_year  = Gtk::RadioButton.new(member: choose_original_year, label: _("From release"))

      table92.attach(label_preferred_country, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(entry_preferred_country, 1, 3, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(label_preferred_release, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(choose_original_release, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(choose_latest_release,   2, 3, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(label_preferred_year,    0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(choose_original_year,    1, 2, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table92.attach(choose_release_year,     2, 3, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)

      @frame92 = new_frame(_("Musicbrainz options"), table92)
    end

    def update_metadata_provider_view
      frame91.children.each { |child| child.sensitive = (metadata_choice.active != 2) }
      frame92.children.each { |child| child.sensitive = (metadata_choice.active != 2) }
    end

    def pack_metadata_frames
      metadata_choice.signal_connect("changed") { update_metadata_provider_view }

      @page3 = Gtk::Box.new(:vertical) # One VBox to rule them all
      [frame90, frame91, frame92].each { |frame| page3.pack_start(frame, expand: false, fill: false) }
      @page3_label = Gtk::Label.new(_("Metadata"))

      display.append_page(page3, page3_label)
    end

    def build_frame_filenaming_scheme
      @table100 = new_table(rows: 8, columns: 2)

      # Creating objects 1st column
      @basedir_label        = Gtk::Label.new(_("Base directory:")); basedir_label.set_alignment(0.0, 0.5)
      @naming_normal_label  = Gtk::Label.new(_("Standard:")); naming_normal_label.set_alignment(0.0, 0.5)
      @naming_various_label = Gtk::Label.new(_("Various artists:")); naming_various_label.set_alignment(0.0, 0.5)
      @naming_image_label   = Gtk::Label.new(_("Single file image:")); naming_image_label.set_alignment(0.0, 0.5)
      @example_label        = Gtk::Label.new(""); example_label.set_alignment(0.0, 0.5); example_label.wrap = true
      @expander100          = Gtk::Expander.new(_("Show options for \"File naming scheme\""))
      @example_label_shows  = "normal"

      # Configure expander
      #@artist_label = Gtk::Label.new(
      #  "%a=artist %b=album %f=codec %g=genre\n%va=various artists %n=track %t=trackname %y=year"
      #)
      @legend_label = Gtk::Label.new(
        "%%a=%s %%g=%s %%t=%s %%f=%s\n%%b=%s %%y=%s %%n=%s %%va=%s" % [
          _("Artist"), _("Genre"), _("Track name"), _("Codec"),
          _("Album"), _("Year"), _("Track"), _("Various artist")
        ]
      )
      expander100.add(@legend_label)

      @no_spaces   = Gtk::CheckButton.new(_("Replace spaces with underscores in file names"))
      @no_capitals = Gtk::CheckButton.new(_("Downsize all capital letters in file names"))
      no_spaces.signal_connect("toggled") { update_example_label }
      no_capitals.signal_connect("toggled") { update_example_label }

      # Packing 1st column
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      expand = Gtk::AttachOptions::EXPAND
      table100.attach(basedir_label,        0, 1, 0, 1, fill,        shrink, 0, 0)
      table100.attach(naming_normal_label,  0, 1, 1, 2, fill,        shrink, 0, 0)
      table100.attach(naming_various_label, 0, 1, 2, 3, fill,        shrink, 0, 0)
      table100.attach(naming_image_label,   0, 1, 3, 4, fill,        shrink, 0, 0)
      table100.attach(no_spaces,            0, 2, 4, 5, fill,        fill,   0, 0)
      table100.attach(no_capitals,          0, 2, 5, 6, fill,        fill,   0, 0)
      table100.attach(example_label,        0, 2, 6, 7, expand|fill, shrink, 0, 0) # Width = 2 cols, also maximise width
      table100.attach(expander100,          0, 2, 7, 8, expand|fill, shrink, 0, 0)

      # Creating objects 2nd column and connect signals to them
      @basedir_entry        = Gtk::Entry.new
      @naming_normal_entry  = Gtk::Entry.new
      @naming_various_entry = Gtk::Entry.new
      @naming_image_entry   = Gtk::Entry.new

      handler1 = -> { show_file_normal; false }
      handler2 = -> { show_file_various; false }
      handler3 = -> { show_file_image; false }
      handler4 = ->(entry) do
        if File.dirname(entry.text) !~ /%a|%b/
          entry.text = "%a (%y) %b/" + entry.text
          prevent_stupidness
        end
        false
      end

      basedir_entry.signal_connect("key_release_event",           &handler1)
      basedir_entry.signal_connect("button_release_event",        &handler1)
      naming_normal_entry.signal_connect("key_release_event",     &handler1)
      naming_normal_entry.signal_connect("button_release_event",  &handler1)
      naming_various_entry.signal_connect("key_release_event",    &handler2)
      naming_various_entry.signal_connect("button_release_event", &handler2)
      naming_image_entry.signal_connect("key_release_event",      &handler3)
      naming_image_entry.signal_connect("button_release_event",   &handler3)
      naming_normal_entry.signal_connect("focus-out-event")  { handler4.call(naming_normal_entry) }
      naming_various_entry.signal_connect("focus-out-event") { handler4.call(naming_various_entry) }
      naming_image_entry.signal_connect("focus-out-event")   { handler4.call(naming_image_entry) }

      # Packing 2nd column
      table100.attach(basedir_entry,        1, 2, 0, 1, expand|fill, shrink, 0, 0)
      table100.attach(naming_normal_entry,  1, 2, 1, 2, expand|fill, shrink, 0, 0)
      table100.attach(naming_various_entry, 1, 2, 2, 3, expand|fill, shrink, 0, 0)
      table100.attach(naming_image_entry,   1, 2, 3, 4, expand|fill, shrink, 0, 0)

      @frame100 = new_frame(_("File naming scheme"), table100)
    end

    def show_file_normal
      backup_prefs_before_example_label_update
      example_label.text = _("Example file name: ") +
        Preferences.show_filename_normal(basedir_entry.text, naming_normal_entry.text)
      @example_label_shows = "normal"
      restore_prefs_after_example_label_update
    end

    def show_file_various
      backup_prefs_before_example_label_update
      example_label.text = _("Example file name: ") +
        Preferences.show_filename_various(basedir_entry.text, naming_various_entry.text)
      @example_label_shows = "various"
      restore_prefs_after_example_label_update
    end

    def show_file_image
      backup_prefs_before_example_label_update
      example_label.text = _("Example file name: ") +
        Preferences.show_filename_various(basedir_entry.text, naming_image_entry.text)
      @example_label_shows = "image"
      restore_prefs_after_example_label_update
    end

    def update_example_label
      if example_label_shows == "various"
        show_file_various
      elsif example_label_shows == "image"
        show_file_image
      else
        show_file_normal
      end
    end

    def backup_prefs_before_example_label_update
      # When `show_file_xxx` runs, some prefs are overwritten to calculate the format, so backup those prefs
      # values and apply the current Gtk values to have the correct display.
      @backup_no_spaces   = prefs.no_spaces
      @backup_no_capitals = prefs.no_capitals
      prefs.no_spaces   = no_spaces.active?
      prefs.no_capitals = no_capitals.active?
    end

    def restore_prefs_after_example_label_update
      # When `show_file_xxx` runs, some prefs are overwritten to calculate the format, so restore those prefs values.
      prefs.no_spaces   = @backup_no_spaces
      prefs.no_capitals = @backup_no_capitals
    end

    def prevent_stupidness
      # Would you believe this actually prevents bug reports?
      puts "You need to make a subdirectory with at least the artist or album"
      puts "name in it. Otherwise your directory will be overwritten each time!"
      puts "To protect you from making these unwise choices this is corrected :P"
    end

    def build_frame_programs_of_choice
      @table110 = new_table(rows: 2, columns: 2)

      # Creating objects
      @editor_label      = Gtk::Label.new(_("Log file viewer: ")); editor_label.set_alignment(0.0, 0.5)
      @filemanager_label = Gtk::Label.new(_("File manager: ")); filemanager_label.set_alignment(0.0, 0.5)
      @editor_entry      = Gtk::Entry.new
      @filemanager_entry = Gtk::Entry.new

      # Packing objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table110.attach(editor_label,      0, 1, 0, 1, fill, shrink, 0, 0)
      table110.attach(filemanager_label, 0, 1, 1, 2, fill, shrink, 0, 0)
      table110.attach(editor_entry,      1, 2, 0, 1, fill, shrink, 0, 0)
      table110.attach(filemanager_entry, 1, 2, 1, 2, fill, shrink, 0, 0)

      @frame110 = new_frame(_("Programs of choice"), table110)
    end

    def build_frame_debug_options
      @table120 = new_table(rows: 1, columns: 2)
      @verbose  = Gtk::CheckButton.new(_("Verbose mode"))
      @debug    = Gtk::CheckButton.new(_("Debug mode"))

      table120.attach(verbose, 0, 1, 0, 1, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::SHRINK)
      table120.attach(debug,   1, 2, 0, 1, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::SHRINK)

      @frame120 = new_frame(_("Debug options"), table120)
    end

    def pack_other_frames
      @page4       = Gtk::Box.new(:vertical)
      @page4_label = Gtk::Label.new(_("Other"))

      [frame100, frame110, frame120].each { |frame| page4.pack_start(frame, expand: false, fill: false) }

      display.signal_connect("switch_page") do |a, b, page|
        if page == 1
          cdrdao_installed
        elsif page == 4
          show_file_normal
        end
      end

      display.append_page(page4, page4_label)
    end
  end
end
end
