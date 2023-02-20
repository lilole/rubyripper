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

    attr_reader :cdrom_entry, :cdrom_label, :cdrom_offset_label, :cdrom_offset_spin, :codec_labels, :deps, :display, :frame40, :offset_button, :pad_missing_samples, :prefs, :table40, :frame50, :table50, :all_chunks, :err_chunks, :max_label, :all_chunks_spin, :err_chunks_spin, :max_spin, :time1, :time2, :time3, :frame60, :table60, :rip_label, :eject, :no_log, :rip_entry, :page1, :page1_label, :table_toc1, :rip_hidden_audio, :mark_hidden_track_label1, :mark_hidden_track_label2, :min_length_hidden_track_spin, :frame_toc1, :table_toc2, :create_cue, :image, :vbox_toc, :frame_toc2, :cdrdao_hbox, :cdrdao, :cdrdao_image, :table_toc3, :append_pregaps, :prepend_pregaps, :frame_toc3

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
      no_log.active              = prefs.noLog

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
        prefs.send(get_codec_for_label(label) + "=", true)
        prefs.send("settings" + get_codec_for_label(label).capitalize + "=", objects[1].text)
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
    def new_table(rows, columns, homogeneous=false)
      Gtk::Table.new(rows, columns, homogeneous).tap do |t|
        t.column_spacings = DEFAULT_COLUMN_SPACINGS
        t.row_spacings    = DEFAULT_ROW_SPACINGS
        t.border_width    = DEFAULT_BORDER_WIDTH
      end
    end

    # Helper to create a frame.
    #
    def new_frame(label, child)
      Gtk::Frame.new(label).tap do |f|
        f.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
        f.border_width = DEFAULT_BORDER_WIDTH
        f.add(child)
      end
    end

    # Secure ripping tab, frame 1
    def build_frame_cdrom_device
      @table40 = newTable(rows=3, columns=3)

      # Creating objects
      @cdrom_label = Gtk::Label.new(_("Cdrom device:")); cdrom_label.set_alignment(0.0, 0.5) # Align to the left
      @cdrom_offset_label = Gtk::Label.new(_("Cdrom offset:")); cdrom_offset_label.set_alignment(0.0, 0.5)
      @cdrom_entry = Gtk::Entry.new; cdrom_entry.width_request = 120
      @cdrom_offset_spin = Gtk::SpinButton.new(-1500.0, 1500.0, 1.0); cdrom_offset_spin.value = 0.0

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
      table40.attach(cdrom_label,        0, 1, 0, 1, fill,   shrink, 0, 0)
      table40.attach(cdrom_offset_label, 0, 1, 1, 2, fill,   shrink, 0, 0)
      table40.attach(cdrom_entry,        1, 2, 0, 1, shrink, shrink, 0, 0)
      table40.attach(cdrom_offset_spin,  1, 2, 1, 2, fill,   shrink, 0, 0)
      table40.attach(offset_button,      2, 3, 1, 2, fill,   shrink, 0, 0)

      # Connect signal
      table40.attach(pad_missing_samples, 0, 2, 2, 3, fill, shrink, 0, 0)
      offset_button.signal_connect("clicked") do
        Thread.new { `#{prefs.browser} #{offset_button.uri}` }
      end
      cdrom_offset_spin.signal_connect("value-changed") { enable_padding_option? }
      @frame40 = new_frame(_("Cdrom device"), table40)
    end

    # Enable the padding option if the offset is > 580 || < -580.
    #
    def enable_padding_option?
      value = cdrom_offset_spin.value.to_i
      pad_missing_samples.sensitive = (value > 580 || value < -580)
    end

    # Secure ripping tab, frame 2.
    #
    def build_frame_ripping_options
      @table50 = new_table(3, 3)

      # Create objects
      @all_chunks      = Gtk::Label.new(_("Match all chunks:")); all_chunks.set_alignment(0.0, 0.5)
      @err_chunks      = Gtk::Label.new(_("Match erroneous chunks:")); err_chunks.set_alignment(0.0, 0.5)
      @max_label       = Gtk::Label.new(_("Maximum trials (0 = unlimited):")); max_label.set_alignment(0.0, 0.5)
      @all_chunks_spin = Gtk::SpinButton.new(2.0,  100.0, 1.0)
      @err_chunks_spin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
      @max_spin        = Gtk::SpinButton.new(0.0, 100.0, 1.0)
      @time1           = Gtk::Label.new(_("times"))
      @time2           = Gtk::Label.new(_("times"))
      @time3           = Gtk::Label.new(_("times"))

      # Pack objects
      fill   = Gtk::AttachOptions::FILL
      shrink = Gtk::AttachOptions::SHRINK
      table50.attach(all_chunks,      0, 1, 0, 1, fill, shrink, 0, 0) # C 1
      table50.attach(err_chunks,      0, 1, 1, 2, fill, shrink, 0, 0)
      table50.attach(max_label,       0, 1, 2, 3, fill, shrink, 0, 0)
      table50.attach(all_chunks_spin, 1, 2, 0, 1, fill, shrink, 0, 0) # C 2
      table50.attach(err_chunks_spin, 1, 2, 1, 2, fill, shrink, 0, 0)
      table50.attach(max_spin,        1, 2, 2, 3, fill, shrink, 0, 0)
      table50.attach(time1,           2, 3, 0, 1, fill, shrink, 0, 0) # C 3
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
      @frame50 = newFrame(_("Ripping options"), table50)
    end

    def build_frame_ripping_related
      @table60 = new_table(2, 3)

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
      @page1 = Gtk::Box.new(:vertical) # One VBox to rule them all
      [frame40, frame50, frame60].each do |frame|
        page1.pack_start(frame, expand: false, fill: false)
      end
      @page1_label = Gtk::Label.new(_("Secure Ripping"))
      display.append_page(page1, page1_label)
    end

    def build_frame_audio_sectors_before_track_one
      # Create objects
      @table_toc1                   = new_table(3, 3)
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
      @table_toc2 = new_table(3, 2)
      @create_cue = Gtk::CheckButton.new(_("Create cuesheet"))
      @image      = Gtk::CheckButton.new(_("Rip CD to single file"))

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
      @table_toc3      = new_table(3, 3)
      @append_pregaps  = Gtk::RadioButton.new(label: _("Append pregap to the previous track"))
      @prepend_pregaps = Gtk::RadioButton.new(member: append_pregaps, label: _("Prepend pregap to the track"))

      # Pack objects
      table_toc3.attach(append_pregaps,  0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      table_toc3.attach(prepend_pregaps, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @frame_toc3 = new_frame(_("Handling pregaps other than track 1"), table_toc3)
      vbox_toc.pack_start(frame_toc3, expand: false, fill: false)
    end

    def buildFrameHandlingTracksWithPreEmphasis
      @tableToc4 = newTable(rows=3, columns=3)
  #create objects
      @correctPreEmphasis = Gtk::RadioButton.new(:label => _("Correct pre-emphasis tracks with sox"))
      @doNotCorrectPreEmphasis = Gtk::RadioButton.new(:member => @correctPreEmphasis,
                                                      :label =>_("Save the pre-emphasis tag in the cuesheet."))
  #pack objects
      @tableToc4.attach(@correctPreEmphasis, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @tableToc4.attach(@doNotCorrectPreEmphasis, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @frameToc4 = newFrame(_("Handling tracks with pre-emphasis"), child=@tableToc4)
      @vboxToc.pack_start(@frameToc4, :expand => false, :fill => false)
  #pack all frames into a single page
      setSignalsToc()
      @pageToc = Gtk::Box.new(:vertical) #One VBox to rule them all
      [@frameToc1, @cdrdaoHbox, @frameToc2].each{|frame| @pageToc.pack_start(frame, :expand => false, :fill => false)}
      @pageTocLabel = Gtk::Label.new(_("TOC analysis"))
      @display.append_page(@pageToc, @pageTocLabel)
    end

    #check if cdrdao is installed
    def cdrdaoInstalled
      if @deps.installed?("cdrdao")
        @cdrdaoImage.stock = Gtk::Stock::APPLY
        @frameToc2.each{|child| child.sensitive = true}
      else
        @cdrdaoImage.stock = Gtk::Stock::CANCEL
        @createCue.active = false
        @frameToc2.each{|child| child.sensitive = false}
      end
    end

    # signal for createCue
    def createCue
      @image.sensitive = @createCue.active?
      @image.active = false if !@createCue.active?
      @tableToc3.each{|child| child.sensitive = @createCue.active?}
      @tableToc4.each{|child| child.sensitive = @createCue.active?}
    end

    # signal for create single file
    def createSingle
      @tableToc3.each{|child| child.sensitive = !@image.active?}
      @correctPreEmphasis.active = true
      @doNotCorrectPreEmphasis.sensitive = !@image.active?
    end

    #set signals for the toc
    def setSignalsToc
      cdrdaoInstalled()
      createSingle()
      createCue()
      @createCue.signal_connect("clicked"){createCue()}
      @createCue.signal_connect("clicked"){`killall cdrdao 2>&1` if !@createCue.active?}
      @image.signal_connect("clicked"){createSingle()}
    end

    def buildFrameSelectAudioCodecs # Select audio codecs frame
      @codecRows = Hash.new
      @prefs.codecs.each{|codec| createCodecRow(codec)}
      @selectCodecsTable = newTable(@codecRows.size + 1, columns = 3)
      createCodecsTable()
      @frame70 = newFrame(_("Active audio codecs"), child=@selectCodecsTable)
    end

    def createCodecRow(codec)
      @codecRows[codec] = [Gtk::Label.new(getLabelForCodec(codec))]
      @codecRows[codec][0].set_alignment(0, 0.5)
      if codec == "wav"
        @codecRows[codec] << Gtk::Label.new(_("No settings available"))
        @codecRows[codec][1].set_alignment(0, 0.5)
      else
        @codecRows[codec] << Gtk::Entry.new()
        @codecRows[codec][1].text = @prefs.send("settings" + codec.capitalize)
      end
      @codecRows[codec] << Gtk::Button.new(:stock_id => Gtk::Stock::REMOVE)
      addTooltipForOtherCodec(@codecRows[codec][1]) if codec == "other"

      # connect the remove button signal
      @codecRows[codec][2].signal_connect("button_release_event") do |a, b|
        @codecRows[codec].each{|object| @selectCodecsTable.remove(object)}
        @codecRows.delete(codec)
        @prefs.send(codec + "=", false)
        updateCodecsView()
      end
    end

    def getLabelForCodec(codec)
      @codec_labels.key?(codec) ? @codec_labels[codec] : codec.capitalize
    end

    def getCodecForLabel(label)
      @codec_labels.value?(label) ? @codec_labels.key(label) : label.downcase
    end

    def updateCodecsView
      @selectCodecsTable.each{|child| @selectCodecsTable.remove(child)}
      @selectCodecsTable.resize(@codecRows.size + 1, columns = 3)
      createCodecsTable()
      @selectCodecsTable.show_all()
    end

    def createCodecsTable
      top = 0
      @codecRows.each do |codec, row|
        @selectCodecsTable.attach(row[0], 0, 1, top, top+1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
        @selectCodecsTable.attach(row[1], 1, 2, top, top+1, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND,
                                  Gtk::AttachOptions::SHRINK, 0, 0)
        @selectCodecsTable.attach(row[2], 2, 3, top, top+1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
        top += 1
      end

      createAddCodecRow()
    end

    def addTooltipForOtherCodec(entry)
      entry.tooltip_text = _("%a=artist %g=genre %t=track name %f=codec %b=album
  %y=year %n=track %va=various artist %o=output file %i=input file")
    end

    def createAddCodecRow
      @addCodecComboBox = Gtk::ComboBoxText.new()
      @prefs.allCodecs.each do |codec|
        @addCodecComboBox.append_text(getLabelForCodec(codec)) unless @codecRows.key?(codec)
      end

      if @addCodecLabel.nil?
        @addCodecLabel = Gtk::Label.new(_("Codec"))
        @addCodecLabel.set_alignment(0, 0.5)
        @addCodecButton = Gtk::Button.new(:stock_id => Gtk::Stock::ADD)

        # create the signal for the button
        @addCodecButton.signal_connect("button_release_event") do |a, b|

          label = @addCodecComboBox.active_text
          if not label.nil?
            createCodecRow(getCodecForLabel(label))
            updateCodecsView()
          end
        end
      end

      # put the row into the table
      top = @codecRows.size
      @selectCodecsTable.attach(@addCodecLabel, 0, 1, top, top+1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @selectCodecsTable.attach(@addCodecComboBox, 1, 2, top, top+1, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND,
                                Gtk::AttachOptions::SHRINK, 0, 0)
      @selectCodecsTable.attach(@addCodecButton, 2, 3, top, top+1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    end

    def buildFrameCodecRelated #Encoding related frame
      @table80 = newTable(rows=2, columns=2)
  #creating objects
      @playlist = Gtk::CheckButton.new(_("Create m3u playlist"))
      @maxThreads = Gtk::SpinButton.new(0.0, 10.0, 1.0)
      @maxThreadsLabel = Gtk::Label.new(_("Number of extra encoding threads"))
  #packing objects
      @table80.attach(@maxThreadsLabel, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @table80.attach(@maxThreads, 1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @table80.attach(@playlist, 0, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @frame80 = newFrame(_("Codec related"), child=@table80)
    end

    def buildFrameNormalizeToStandardVolume #Normalize audio
      @table85 = newTable(rows=2, columns=1)
  #creating objects
      @normalize = Gtk::ComboBoxText.new()
      @normalize.append_text(_("Don't standardize volume"))
      @normalize.append_text(_("Use replaygain on audio files"))
      @normalize.append_text(_("Use normalize on WAVE files"))
      @normalize.active=0
      @modus = Gtk::ComboBoxText.new()
      @modus.append_text(_("Album / Audiophile modus"))
      @modus.append_text(_("Track modus"))
      @modus.active = 0
      @modus.sensitive = false
      @normalize.signal_connect("changed") {if @normalize.active == 0 ; @modus.sensitive = false else @modus.sensitive = true end}
  #packing objects
      @table85.attach(@normalize, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @table85.attach(@modus, 1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @frame85 = newFrame(_("Normalize to standard volume"), child=@table85)
  #pack all frames into a single page
      @page2 = Gtk::Box.new(:vertical) #One VBox to rule them all
      [@frame70, @frame80, @frame85].each{|frame| @page2.pack_start(frame, :expand => false, :fill => false)}
      @page2_label = Gtk::Label.new(_("Codecs"))
      @display.append_page(@page2, @page2_label)
    end

    def buildFrameChooseMetadataProvider
      @table90 = newTable(rows=1, columns=2)
      @metadataLabel = Gtk::Label.new(_("Primary metadata provider:"))
      @metadataChoice = Gtk::ComboBoxText.new()
      @metadataChoice.append_text(_("Gnudb"))
      @metadataChoice.append_text(_("Musicbrainz"))
      @metadataChoice.append_text(_("Don't use a metadata provider"))
      @table90.attach(@metadataLabel,0,1,0,1,Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK,0,0)
      @table90.attach(@metadataChoice,1,2,0,1,Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK,0,0)
      @frame90 = newFrame(_("Choose your metadata provider"), child=@table90)
    end

    def buildFrameFreedbOptions
      @table91 = newTable(rows=4, columns=2)
  #creating objects
      @firstHit= Gtk::CheckButton.new(_("Always use first gnudb hit"))
      @freedb_server_label= Gtk::Label.new(_("Gnudb server:")) ; @freedb_server_label.set_alignment(0.0, 0.5)
      @freedb_username_label= Gtk::Label.new(_("Username:")) ; @freedb_username_label.set_alignment(0.0, 0.5)
      @freedb_hostname_label= Gtk::Label.new(_("Hostname:")) ; @freedb_hostname_label.set_alignment(0.0, 0.5)
      @freedbServerEntry = Gtk::Entry.new
      @freedbUsernameEntry = Gtk::Entry.new
      @freedbHostnameEntry = Gtk::Entry.new
  #packing objects
      @table91.attach(@firstHit, 0, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #both columns, 2nd row
      @table91.attach(@freedb_server_label, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #1st column, 3rd row
      @table91.attach(@freedb_username_label, 0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #1st column, 4th row
      @table91.attach(@freedb_hostname_label, 0, 1, 3, 4, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #1st column, 5th row
      @table91.attach(@freedbServerEntry, 1, 2 , 1, 2, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND,
                      Gtk::AttachOptions::SHRINK, 0, 0) #2nd column, 3rd row
      @table91.attach(@freedbUsernameEntry, 1, 2, 2, 3, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND,
                      Gtk::AttachOptions::SHRINK, 0, 0) #2nd column, 4th row
      @table91.attach(@freedbHostnameEntry, 1, 2, 3, 4, Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND,
                      Gtk::AttachOptions::SHRINK, 0, 0) #2nd column, 5th row
      @frame91 = newFrame(_("Gnudb options"), child=@table91)
  #pack frame
    end

    def buildFrameMusicbrainzOptions
      @table92 = newTable(rows=3, columns=3)
      @labelPreferredCountry = Gtk::Label.new(_("Preferred countries:"))
      @labelPreferredCountry.set_alignment(0.0, 0.5)
      @labelPreferredRelease = Gtk::Label.new(_("Preferred release date:"))
      @labelPreferredRelease.set_alignment(0.0, 0.5)
      @labelPreferredYear = Gtk::Label.new(_("Preferred year (metadata):"))
      @labelPreferredYear.set_alignment(0.0, 0.5)
      @entryPreferredCountry = Gtk::Entry.new()
      @chooseOriginalRelease = Gtk::RadioButton.new(:label => _("Original"))
      @chooseLatestRelease = Gtk::RadioButton.new(:member => @chooseOriginalRelease, :label => _("Latest available"))
      @chooseOriginalYear = Gtk::RadioButton.new(:label => _("Original"))
      @chooseReleaseYear = Gtk::RadioButton.new(:member => @chooseOriginalYear, :label => _("From release"))
  #packing objects
      @table92.attach(@labelPreferredCountry, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@entryPreferredCountry, 1, 3, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@labelPreferredRelease, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@chooseOriginalRelease, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@chooseLatestRelease, 2, 3, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@labelPreferredYear, 0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@chooseOriginalYear, 1, 2, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table92.attach(@chooseReleaseYear, 2, 3, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @frame92 = newFrame(_("Musicbrainz options"), @table92)
    end

    # grey out the two frames if no metadata provider is chosen
    def updateMetadataProviderView
      @frame91.children.each{|child| child.sensitive = @metadataChoice.active != 2}
      @frame92.children.each{|child| child.sensitive = @metadataChoice.active != 2}
    end

    def packMetadataFrames
      @metadataChoice.signal_connect("changed"){updateMetadataProviderView()}
      @page3 = Gtk::Box.new(:vertical) #One VBox to rule them all
      [@frame90, @frame91, @frame92].each{|frame| @page3.pack_start(frame, :expand => false, :fill => false)}
      @page3_label = Gtk::Label.new(_("Metadata"))
      @display.append_page(@page3, @page3_label)
    end

    def buildFrameFilenamingScheme # Naming scheme frame
      @table100 = newTable(rows=8, columns=2)
  #creating objects 1st column
      @basedir_label = Gtk::Label.new(_("Base directory:")) ; @basedir_label.set_alignment(0.0, 0.5) #set_alignment(xalign=0.0, yalign=0.5)
      @naming_normal_label = Gtk::Label.new(_("Standard:")) ; @naming_normal_label.set_alignment(0.0, 0.5)
      @naming_various_label = Gtk::Label.new(_("Various artists:")) ; @naming_various_label.set_alignment(0.0, 0.5)
      @naming_image_label = Gtk::Label.new(_("Single file image:")) ; @naming_image_label.set_alignment(0.0, 0.5)
      @example_label =Gtk::Label.new("") ; @example_label.set_alignment(0.0, 0.5) ; @example_label.wrap = true
      @expander100 = Gtk::Expander.new(_("Show options for "File naming scheme""))
      @example_label_shows = "normal"
  #configure expander
      #@artist_label = Gtk::Label.new("%a = artist   %b = album   %f = codec   %g = genre\n%va = various artists   %n = track   %t = trackname   %y = year")
      @legend_label = Gtk::Label.new("%a=" + _("Artist") + " %g=" + _("Genre") + " %t=" + _("Track name") +
                                       " %f=" + _("Codec") + "\n%b=" + _("Album") + " %y=" + _("Year") +
                                      " %n=" + _("Track") + " %va=" + _("Various artist"))
      @expander100.add(@legend_label)
      @noSpaces = Gtk::CheckButton.new(_("Replace spaces with underscores in file names"))
      @noCapitals = Gtk::CheckButton.new(_("Downsize all capital letters in file names"))
      @noSpaces.signal_connect("toggled") { updateExampleLabel() }
      @noCapitals.signal_connect("toggled") { updateExampleLabel() }
  #packing 1st column
      @table100.attach(@basedir_label, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@naming_normal_label, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@naming_various_label, 0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@naming_image_label, 0, 1, 3, 4, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@noSpaces, 0, 2, 4, 5, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @table100.attach(@noCapitals, 0, 2, 5, 6, Gtk::AttachOptions::FILL, Gtk::AttachOptions::FILL, 0, 0)
      @table100.attach(@example_label, 0, 2, 6, 7, Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL,
                       Gtk::AttachOptions::SHRINK, 0, 0) #width = 2 columns, also maximise width
      @table100.attach(@expander100, 0, 2 , 7, 8, Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL,
                       Gtk::AttachOptions::SHRINK, 0, 0)
  #creating objects 2nd column and connect signals to them
      @basedirEntry = Gtk::Entry.new
      @namingNormalEntry = Gtk::Entry.new
      @namingVariousEntry = Gtk::Entry.new
      @namingImageEntry = Gtk::Entry.new
      @basedirEntry.signal_connect("key_release_event"){showFileNormal() ; false}
      @basedirEntry.signal_connect("button_release_event"){showFileNormal() ; false}
      @namingNormalEntry.signal_connect("key_release_event"){showFileNormal() ; false}
      @namingNormalEntry.signal_connect("button_release_event"){showFileNormal() ; false}
      @namingNormalEntry.signal_connect("focus-out-event"){if not File.dirname(@namingNormalEntry.text) =~ /%a|%b/ ; @namingNormalEntry.text = "%a (%y) %b/" + @namingNormalEntry.text; preventStupidness() end; false}
      @namingVariousEntry.signal_connect("key_release_event"){showFileVarious() ; false}
      @namingVariousEntry.signal_connect("button_release_event"){showFileVarious() ; false}
      @namingVariousEntry.signal_connect("focus-out-event"){if not File.dirname(@namingVariousEntry.text) =~ /%a|%b/ ; @namingVariousEntry.text = "%a (%y) %b/" + @namingVariousEntry.text; preventStupidness() end; false}
      @namingImageEntry.signal_connect("key_release_event"){showFileImage() ; false}
      @namingImageEntry.signal_connect("button_release_event"){showFileImage() ; false}
      @namingImageEntry.signal_connect("focus-out-event"){if not File.dirname(@namingImageEntry.text) =~ /%a|%b/ ; @namingImageEntry.text = "%a (%y) %b/" + @namingImageEntry.text; preventStupidness() end; false}
  #packing 2nd column
      @table100.attach(@basedirEntry, 1, 2, 0, 1, Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@namingNormalEntry, 1, 2, 1, 2, Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL,
                       Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@namingVariousEntry, 1, 2, 2, 3, Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL,
                       Gtk::AttachOptions::SHRINK, 0, 0)
      @table100.attach(@namingImageEntry, 1, 2, 3, 4, Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL,
                       Gtk::AttachOptions::SHRINK, 0, 0)
      @frame100 = newFrame(_("File naming scheme"), child=@table100)
    end

    def showFileNormal
      backupPrefsBeforeExampleLabelUpdate()
      @example_label.text = _("Example file name: ") +
        Preferences.showFilenameNormal( @basedirEntry.text, @namingNormalEntry.text)
      @example_label_shows = "normal"
      restorePrefsAfterExampleLabelUpdate()
    end

    def showFileVarious
      backupPrefsBeforeExampleLabelUpdate()
      @example_label.text = _("Example file name: ") +
        Preferences.showFilenameVarious(@basedirEntry.text, @namingVariousEntry.text)
      @example_label_shows = "various"
      restorePrefsAfterExampleLabelUpdate()
    end

    def showFileImage
      backupPrefsBeforeExampleLabelUpdate()
      @example_label.text = _("Example file name: ") +
        Preferences.showFilenameVarious(@basedirEntry.text, @namingImageEntry.text)
      @example_label_shows = "image"
      restorePrefsAfterExampleLabelUpdate()
    end

    def updateExampleLabel
      if @example_label_shows == "various"
        showFileVarious()
      elsif @example_label_shows == "image"
        showFileImage()
      else
        showFileNormal()
      end
    end

    # showFileXXX uses @prefs to calculate the format;
    # backup/restore some prefs values and apply the current Gtk values to have the correct display
    def backupPrefsBeforeExampleLabelUpdate
      @backupNoSpaces = @prefs.noSpaces
      @backupNoCapitals = @prefs.noCapitals
      @prefs.noSpaces = @noSpaces.active?
      @prefs.noCapitals = @noCapitals.active?
    end

    def restorePrefsAfterExampleLabelUpdate
      @prefs.noSpaces = @backupNoSpaces
      @prefs.noCapitals = @backupNoCapitals
    end

    # Would you believe this actually prevents bug reports?
    def preventStupidness()
      puts "You need to make a subdirectory with at least the artist or album"
      puts "name in it. Otherwise your directory will be overwritten each time!"
      puts "To protect you from making these unwise choices this is corrected :P"
    end

  #Small table needed for setting programs
  #log file viewer 	| entry
  #file manager 	| entry
    def buildFrameProgramsOfChoice
      @table110 = newTable(rows=2, columns=2)
  #creating objects
      @editor_label = Gtk::Label.new(_("Log file viewer: ")) ; @editor_label.set_alignment(0.0, 0.5)
      @filemanager_label = Gtk::Label.new(_("File manager: ")) ; @filemanager_label.set_alignment(0.0,0.5)
      @editorEntry = Gtk::Entry.new
      @filemanagerEntry = Gtk::Entry.new
  #packing objects
      @table110.attach(@editor_label, 0,1,0,1,Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table110.attach(@filemanager_label, 0,1,1,2,Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table110.attach(@editorEntry, 1,2,0,1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @table110.attach(@filemanagerEntry, 1,2,1,2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @frame110 = newFrame(_("Programs of choice"), child=@table110)
    end

  #Small table for debugging
  #Verbose mode	| debug mode
    def buildFrameDebugOptions # Debug options frame
      @table120 = newTable(rows=1, columns=2)
  #creating objects and packing them
      @verbose = Gtk::CheckButton.new(_("Verbose mode"))
      @debug = Gtk::CheckButton.new(_("Debug mode"))
      @table120.attach(@verbose, 0,1,0,1,Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::SHRINK)
      @table120.attach(@debug, 1,2,0,1,Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::SHRINK)
      @frame120 = newFrame(_("Debug options"), child=@table120)
    end

    def pack_other_frames #pack all frames into a single page
      @page4 = Gtk::Box.new(:vertical)
      [@frame100, @frame110, @frame120].each{|frame| @page4.pack_start(frame, :expand => false, :fill => false)}
      @page4_label = Gtk::Label.new(_("Other"))
      @display.signal_connect("switch_page") do |a, b, page|
        if page == 1
          cdrdaoInstalled()
        elsif page == 4
          showFileNormal()
        end
      end
      @display.append_page(@page4, @page4_label)
    end
  end
end
end
