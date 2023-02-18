#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2013 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

# The class GtkPreferences allows the user to change his preferences
# This class is responsible for building the frame on the right side

class GtkPreferences
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  DEFAULT_COLUMN_SPACINGS = 5
  DEFAULT_ROW_SPACINGS = 4
  DEFAULT_BORDER_WIDTH = 7

  def initialize(prefs=nil, deps=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance
    @codec_labels = {'flac' => 'FLAC', 'wavpack' => 'WavPack', 'nero' => 'Nero AAC',
                     'fraunhofer' => 'Fraunhofer AAC', 'other' => _('Other')}
  end
  
  def start
    @display = Gtk::Notebook.new # Create a notebook (multiple pages)
    buildSecureRippingTab()
    buildTocAnalysisTab()
    buildCodecsTab()
    buildMetadataTab()
    buildOtherTab()
    loadPreferences()
  end
  
  # save current preferences
  def save
    savePreferences
  end
  
  private
  
  # build first tab
  def buildSecureRippingTab
    buildFrameCdromDevice()
    buildFrameRippingOptions()
    buildFrameRippingRelated()
  end
  
  # build second tab
  def buildTocAnalysisTab
    buildFrameAudioSectorsBeforeTrackOne()
    buildFrameAdvancedTocAnalysis()
    buildFrameHandlingPregapsOtherThanTrackOne()
    buildFrameHandlingTracksWithPreEmphasis()
  end
  
  # build third tab
  def buildCodecsTab
    buildFrameSelectAudioCodecs()
    buildFrameCodecRelated()
    buildFrameNormalizeToStandardVolume()
  end
  
  # build fourth tab
  def buildMetadataTab
    buildFrameChooseMetadataProvider()
    buildFrameFreedbOptions()
    buildFrameMusicbrainzOptions()
    packMetadataFrames()
  end
  
  # build fifth tab
  def buildOtherTab
    buildFrameFilenamingScheme()
    buildFrameProgramsOfChoice()
    buildFrameDebugOptions()
    pack_other_frames()
  end

  # Fill all objects with the right value
  def loadPreferences
#ripping settings
    @cdromEntry.text = @prefs.cdrom
    @cdromOffsetSpin.value = @prefs.offset.to_f
    @padMissingSamples.active = @prefs.padMissingSamples
    @allChunksSpin.value = @prefs.reqMatchesAll.to_f
    @errChunksSpin.value = @prefs.reqMatchesErrors.to_f
    @maxSpin.value = @prefs.maxTries.to_f
    @ripEntry.text = @prefs.rippersettings
    @eject.active = @prefs.eject
    @noLog.active = @prefs.noLog
#toc settings
    @createCue.active = @prefs.createCue
    @image.active = @prefs.image
    @ripHiddenAudio.active = @prefs.ripHiddenAudio
    @minLengthHiddenTrackSpin.value = @prefs.minLengthHiddenTrack.to_f
    @appendPregaps.active = @prefs.preGaps == 'append'
    @prependPregaps.active = @prefs.preGaps == 'prepend'
    @correctPreEmphasis.active = @prefs.preEmphasis == 'sox'
    @doNotCorrectPreEmphasis.active = @prefs.preEmphasis == 'cue'
#codec settings (codecs itself are loaded when the objects are created)
    @playlist.active = @prefs.playlist
    @noSpaces.active = @prefs.noSpaces
    @noCapitals.active = @prefs.noCapitals
    @maxThreads.value = @prefs.maxThreads.to_f
    @normalize.active = loadNormalizer()
    @modus.active = @prefs.gain == 'album' ? 0 : 1
#metadata
    @metadataChoice.active = loadMetadataProvider()
    @firstHit.active = @prefs.firstHit
    @freedbServerEntry.text = @prefs.site
    @freedbUsernameEntry.text = @prefs.username
    @freedbHostnameEntry.text = @prefs.hostname
    @entryPreferredCountry.text = @prefs.preferMusicBrainzCountries
    @chooseOriginalRelease.active = @prefs.preferMusicBrainzDate == 'earlier'
    @chooseLatestRelease.active = @prefs.preferMusicBrainzDate == 'later'
    @chooseOriginalYear.active = @prefs.useEarliestDate
    @chooseReleaseYear.active = !@prefs.useEarliestDate
#other
    @basedirEntry.text = @prefs.basedir
    @namingNormalEntry.text = @prefs.namingNormal
    @namingVariousEntry.text = @prefs.namingVarious
    @namingImageEntry.text = @prefs.namingImage
    @verbose.active = @prefs.verbose
    @debug.active = @prefs.debug
    @editorEntry.text = @prefs.editor
    @filemanagerEntry.text = @prefs.filemanager
  end
  
  def loadNormalizer
    case @prefs.normalizer
      when 'none' then 0
      when 'replaygain' then 1
      when 'normalize' then 2
    end
  end
  
  def loadMetadataProvider
    case @prefs.metadataProvider
      when 'freedb' then 0
      when 'gnudb' then 0
      when 'musicbrainz' then 1
      when 'none' then 2
    end
  end

  # update the preferences object with latest values
  def savePreferences
#ripping settings
    @prefs.cdrom = @cdromEntry.text
    @prefs.offset = @cdromOffsetSpin.value.to_i
    @prefs.padMissingSamples = @padMissingSamples.active?
    @prefs.reqMatchesAll = @allChunksSpin.value.to_i
    @prefs.reqMatchesErrors = @errChunksSpin.value.to_i
    @prefs.maxTries = @maxSpin.value.to_i
    @prefs.rippersettings = @ripEntry.text
    @prefs.eject = @eject.active?
    @prefs.noLog = @noLog.active?
#toc settings
    @prefs.createCue = @createCue.active?
    @prefs.image = @image.active?
    @prefs.ripHiddenAudio = @ripHiddenAudio.active?
    @prefs.minLengthHiddenTrack = @minLengthHiddenTrackSpin.value.to_i
    @prefs.preGaps = @appendPregaps.active? ? 'append' : 'prepend'
    @prefs.preEmphasis = @correctPreEmphasis.active? ? 'sox' : 'cue'
#codec settings
    @codecRows.each do |label, objects|
      @prefs.send(getCodecForLabel(label) + '=', true)
      @prefs.send('settings' + getCodecForLabel(label).capitalize + '=', objects[1].text)
    end
    @prefs.playlist = @playlist.active?
    @prefs.noSpaces = @noSpaces.active?
    @prefs.noCapitals = @noCapitals.active?
    @prefs.maxThreads = @maxThreads.value.to_i
    @prefs.normalizer = saveNormalizer()
    @prefs.gain = @modus.active == 0 ? "album" : "track"
#metadata
    @prefs.metadataProvider = saveMetadataProvider()
    @prefs.firstHit = @firstHit.active?
    @prefs.site = @freedbServerEntry.text
    @prefs.username = @freedbUsernameEntry.text
    @prefs.hostname = @freedbHostnameEntry.text
    @prefs.preferMusicBrainzCountries = @entryPreferredCountry.text
    @prefs.preferMusicBrainzDate = @chooseOriginalRelease.active? ? 'earlier' : 'later'
    @prefs.useEarliestDate = @chooseOriginalYear.active?
#other
    @prefs.basedir = @basedirEntry.text
    @prefs.namingNormal = @namingNormalEntry.text
    @prefs.namingVarious = @namingVariousEntry.text
    @prefs.namingImage = @namingImageEntry.text
    @prefs.verbose = @verbose.active?
    @prefs.debug = @debug.active?
    @prefs.editor = @editorEntry.text
    @prefs.filemanager = @filemanagerEntry.text
    @prefs.save() #also update the config file
  end
  
  def saveNormalizer
    case @normalize.active
      when 0 then 'none'
      when 1 then 'replaygain'
      when 2 then 'normalize'
    end
  end
  
  def saveMetadataProvider
    case @metadataChoice.active
      when 0 then 'gnudb'
      when 1 then 'musicbrainz'
      when 2 then 'none'
    end
  end
  
  # helpfunction to create a table
  def newTable(rows, columns, homogeneous=false)
    table = Gtk::Table.new(rows, columns, homogeneous)
    table.column_spacings = DEFAULT_COLUMN_SPACINGS
    table.row_spacings = DEFAULT_ROW_SPACINGS
    table.border_width = DEFAULT_BORDER_WIDTH
    table
  end
  
  # helpfunction to create a frame
  def newFrame(label, child)
    frame = Gtk::Frame.new(label)
    frame.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
    frame.border_width = DEFAULT_BORDER_WIDTH # was 5
    frame.add(child)
    frame
  end

  # 1st frame on secure ripping tab
  def buildFrameCdromDevice
    @table40 = newTable(rows=3, columns=3)
#creating objects
    @cdrom_label = Gtk::Label.new(_("Cdrom device:"))
    @cdrom_label.set_alignment(0.0, 0.5) # Align to the left
    @cdrom_offset_label = Gtk::Label.new(_("Cdrom offset:"))
    @cdrom_offset_label.set_alignment(0.0, 0.5)
    @cdromEntry = Gtk::Entry.new ; @cdromEntry.width_request = 120
    @cdromOffsetSpin = Gtk::SpinButton.new(-1500.0, 1500.0, 1.0)
    @cdromOffsetSpin.value = 0.0
    @offset_button = Gtk::LinkButton.new(_('List with offsets'))
    @offset_button.uri = "http://www.accuraterip.com/driveoffsets.htm"
    @offset_button.tooltip_text = _("A website which lists the offset for most drives.\nYour drivename can be found in each logfile.")
#pack objects
    @padMissingSamples = Gtk::CheckButton.new(_('Pad missing samples with zero\'s'))
    @padMissingSamples.tooltip_text = _("Cdparanoia can\'t handle offsets \
larger than 580 for \nfirst (negative offset) and last (positive offset) \
track.\nThis option fills the rest with empty samples.\n\
If disabled, the file will not have the correct size.\n\
It is recommended to enable this option.")
    @padMissingSamples.sensitive = false
    @table40.attach(@cdrom_label, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table40.attach(@cdrom_offset_label, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table40.attach(@cdromEntry, 1, 2, 0, 1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 0, 0)
    @table40.attach(@cdromOffsetSpin, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table40.attach(@offset_button, 2, 3, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
#connect signal
    @table40.attach(@padMissingSamples, 0, 2, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @offset_button.signal_connect("clicked") {Thread.new{`#{@prefs.browser} #{@offset_button.uri}`}}
    @cdromOffsetSpin.signal_connect("value-changed"){enablePaddingOption?}
    @frame40 = newFrame(_('Cdrom device'), child=@table40)
  end
  
  # enable the padding option if the offset is >580 || <-580
  def enablePaddingOption?
    value = @cdromOffsetSpin.value.to_i
    if value > 580 || value <-580
      @padMissingSamples.sensitive = true
    else
      @padMissingSamples.sensitive = false
    end
  end

  # 2nd frame on secure ripping tab
  def buildFrameRippingOptions
    @table50 = newTable(rows=3, columns=3)
#create objects
    @all_chunks = Gtk::Label.new(_("Match all chunks:")) ; @all_chunks.set_alignment(0.0, 0.5)
    @err_chunks = Gtk::Label.new(_("Match erroneous chunks:")) ; @err_chunks.set_alignment(0.0, 0.5)
    @max_label = Gtk::Label.new(_("Maximum trials (0 = unlimited):")) ; @max_label.set_alignment(0.0, 0.5)
    @allChunksSpin = Gtk::SpinButton.new(2.0,  100.0, 1.0)
    @errChunksSpin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
    @maxSpin = Gtk::SpinButton.new(0.0, 100.0, 1.0)
    @time1 = Gtk::Label.new(_("times"))
    @time2 = Gtk::Label.new(_("times"))
    @time3 = Gtk::Label.new(_("times"))
#pack objects
    @table50.attach(@all_chunks, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #1st column
    @table50.attach(@err_chunks, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table50.attach(@max_label, 0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table50.attach(@allChunksSpin, 1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #2nd column
    @table50.attach(@errChunksSpin, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table50.attach(@maxSpin, 1, 2, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table50.attach(@time1, 2, 3, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0) #3rd column
    @table50.attach(@time2, 2, 3, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table50.attach(@time3, 2, 3, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
#connect a signal to @all_chunks to make sure @err_chunks get always at least the same amount of rips as @all_chunks
    @allChunksSpin.signal_connect("value_changed") {if @errChunksSpin.value < @allChunksSpin.value ; @errChunksSpin.value = @allChunksSpin.value end ; @errChunksSpin.set_range(@allChunksSpin.value,100.0)} #ensure all_chunks cannot be smaller that err_chunks.
    @frame50= newFrame(_('Ripping options'), child=@table50)
  end

  def buildFrameRippingRelated
    @table60 = newTable(rows=2, columns=3)
#create objects
    @rip_label = Gtk::Label.new(_("Pass cdparanoia options:")) ; @rip_label.set_alignment(0.0, 0.5)
    @eject= Gtk::CheckButton.new(_('Eject cd when finished'))
    @noLog = Gtk::CheckButton.new(_('Only keep logfile if correction is needed'))
    @ripEntry= Gtk::Entry.new ; @ripEntry.width_request = 120
#pack objects
    @table60.attach(@rip_label, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table60.attach(@ripEntry, 1, 2, 0, 1, Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 0, 0)
    @table60.attach(@eject, 0, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table60.attach(@noLog, 0, 2, 2, 3, Gtk::AttachOptions::FILL|Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 0, 0)
    @frame60 = newFrame(_('Ripping related'), child=@table60)
#pack all frames into a single page
    @page1 = Gtk::Box.new(:vertical) #One VBox to rule them all
    [@frame40, @frame50, @frame60].each{|frame| @page1.pack_start(frame, :expand => false, :fill => false)}
    @page1_label = Gtk::Label.new(_("Secure Ripping"))
    @display.append_page(@page1, @page1_label)
  end

  def buildFrameAudioSectorsBeforeTrackOne
    @tableToc1 = newTable(rows=3, columns=3)
#create objects
    @ripHiddenAudio = Gtk::CheckButton.new(_('Rip hidden audio sectors'))
    @markHiddenTrackLabel1 = Gtk::Label.new(_('Mark as a hidden track when longer than'))
    @markHiddenTrackLabel2 = Gtk::Label.new(_('second(s)'))
    @minLengthHiddenTrackSpin = Gtk::SpinButton.new(0, 30, 1)
    @minLengthHiddenTrackSpin.value = 2.0
    @ripHiddenAudio.tooltip_text = _("Uncheck this if cdparanoia crashes with your ripping drive.")
    text = _("A hidden track will rip to a seperate file if used in track modus.\nIf it's smaller the sectors will be prepended to the first track.")
    @minLengthHiddenTrackSpin.tooltip_text = text
    @markHiddenTrackLabel1.tooltip_text = text
    @markHiddenTrackLabel2.tooltip_text = text
#pack objects
    @tableToc1.attach(@ripHiddenAudio, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @tableToc1.attach(@markHiddenTrackLabel1, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @tableToc1.attach(@minLengthHiddenTrackSpin, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @tableToc1.attach(@markHiddenTrackLabel2, 2, 3, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @ripHiddenAudio.signal_connect("clicked"){@minLengthHiddenTrackSpin.sensitive = @ripHiddenAudio.active?}
    @frameToc1 = newFrame(_('Audio sectors before track 1'), child=@tableToc1)
  end

  def buildFrameAdvancedTocAnalysis
    @tableToc2 = newTable(rows=3, columns=2)
    #create objects
    @createCue = Gtk::CheckButton.new(_('Create cuesheet'))
    @image = Gtk::CheckButton.new(_('Rip CD to single file'))
#pack objects
    @tableToc2.attach(@createCue, 0, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @tableToc2.attach(@image, 0, 2, 2, 3, Gtk::AttachOptions::FILL|Gtk::AttachOptions::SHRINK, Gtk::AttachOptions::SHRINK, 0, 0)
    @vboxToc = Gtk::Box.new(:vertical)
    @vboxToc.pack_start(@tableToc2, :expand => false, :fill => false)
    @frameToc2 = newFrame(_('Advanced Toc analysis'), child=@vboxToc)
# build hbox for cdrdao
    @cdrdaoHbox = Gtk::Box.new(:horizontal, 5)
    @cdrdao = Gtk::Label.new(_('Cdrdao installed?'))
    @cdrdaoImage = Gtk::Image.new(:stock => Gtk::Stock::CANCEL, :size => Gtk::IconSize::BUTTON)
    @cdrdaoHbox.pack_start(@cdrdao, :expand => false, :fill => false, :padding => 5)
    @cdrdaoHbox.pack_start(@cdrdaoImage, :expand => false, :fill => false)
  end

  def buildFrameHandlingPregapsOtherThanTrackOne
    @tableToc3 = newTable(rows=3, columns=3)
#create objects
    @appendPregaps = Gtk::RadioButton.new(:label => _('Append pregap to the previous track'))
    @prependPregaps = Gtk::RadioButton.new(:member => @appendPregaps, :label => _('Prepend pregap to the track'))
#pack objects
    @tableToc3.attach(@appendPregaps, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @tableToc3.attach(@prependPregaps, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @frameToc3 = newFrame(_('Handling pregaps other than track 1'), child=@tableToc3)
    @vboxToc.pack_start(@frameToc3, :expand => false, :fill => false)
  end

  def buildFrameHandlingTracksWithPreEmphasis
    @tableToc4 = newTable(rows=3, columns=3)
#create objects
    @correctPreEmphasis = Gtk::RadioButton.new(:label => _('Correct pre-emphasis tracks with sox'))
    @doNotCorrectPreEmphasis = Gtk::RadioButton.new(:member => @correctPreEmphasis,
                                                    :label =>_("Save the pre-emphasis tag in the cuesheet."))
#pack objects
    @tableToc4.attach(@correctPreEmphasis, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @tableToc4.attach(@doNotCorrectPreEmphasis, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @frameToc4 = newFrame(_('Handling tracks with pre-emphasis'), child=@tableToc4)
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
    if @deps.installed?('cdrdao')
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
    @frame70 = newFrame(_('Active audio codecs'), child=@selectCodecsTable)
  end

  def createCodecRow(codec)
    @codecRows[codec] = [Gtk::Label.new(getLabelForCodec(codec))]
    @codecRows[codec][0].set_alignment(0, 0.5)
    if codec == 'wav'
      @codecRows[codec] << Gtk::Label.new(_('No settings available'))
      @codecRows[codec][1].set_alignment(0, 0.5)
    else
      @codecRows[codec] << Gtk::Entry.new()
      @codecRows[codec][1].text = @prefs.send('settings' + codec.capitalize)
    end
    @codecRows[codec] << Gtk::Button.new(:stock_id => Gtk::Stock::REMOVE)
    addTooltipForOtherCodec(@codecRows[codec][1]) if codec == 'other'

    # connect the remove button signal
    @codecRows[codec][2].signal_connect("button_release_event") do |a, b|
      @codecRows[codec].each{|object| @selectCodecsTable.remove(object)}
      @codecRows.delete(codec)
      @prefs.send(codec + '=', false)
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
    entry.tooltip_text = _('%a=artist %g=genre %t=track name %f=codec %b=album 
%y=year %n=track %va=various artist %o=output file %i=input file') 
  end
  
  def createAddCodecRow
    @addCodecComboBox = Gtk::ComboBoxText.new()
    @prefs.allCodecs.each do |codec|
      @addCodecComboBox.append_text(getLabelForCodec(codec)) unless @codecRows.key?(codec)
    end
    
    if @addCodecLabel.nil?
      @addCodecLabel = Gtk::Label.new(_('Codec'))
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
    @frame80 = newFrame(_('Codec related'), child=@table80)
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
    @frame85 = newFrame(_('Normalize to standard volume'), child=@table85)
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
    @frame90 = newFrame(_('Choose your metadata provider'), child=@table90)
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
    @frame91 = newFrame(_('Gnudb options'), child=@table91)
#pack frame
  end
  
  def buildFrameMusicbrainzOptions
    @table92 = newTable(rows=3, columns=3)
    @labelPreferredCountry = Gtk::Label.new(_('Preferred countries:'))
    @labelPreferredCountry.set_alignment(0.0, 0.5)
    @labelPreferredRelease = Gtk::Label.new(_('Preferred release date:'))
    @labelPreferredRelease.set_alignment(0.0, 0.5)
    @labelPreferredYear = Gtk::Label.new(_('Preferred year (metadata):'))
    @labelPreferredYear.set_alignment(0.0, 0.5)
    @entryPreferredCountry = Gtk::Entry.new()
    @chooseOriginalRelease = Gtk::RadioButton.new(:label => _('Original'))
    @chooseLatestRelease = Gtk::RadioButton.new(:member => @chooseOriginalRelease, :label => _('Latest available'))
    @chooseOriginalYear = Gtk::RadioButton.new(:label => _('Original'))
    @chooseReleaseYear = Gtk::RadioButton.new(:member => @chooseOriginalYear, :label => _('From release'))
#packing objects
    @table92.attach(@labelPreferredCountry, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@entryPreferredCountry, 1, 3, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@labelPreferredRelease, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@chooseOriginalRelease, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@chooseLatestRelease, 2, 3, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@labelPreferredYear, 0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@chooseOriginalYear, 1, 2, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @table92.attach(@chooseReleaseYear, 2, 3, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
    @frame92 = newFrame(_('Musicbrainz options'), @table92)
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
    @basedir_label = Gtk::Label.new(_('Base directory:')) ; @basedir_label.set_alignment(0.0, 0.5) #set_alignment(xalign=0.0, yalign=0.5)
    @naming_normal_label = Gtk::Label.new(_('Standard:')) ; @naming_normal_label.set_alignment(0.0, 0.5)
    @naming_various_label = Gtk::Label.new(_('Various artists:')) ; @naming_various_label.set_alignment(0.0, 0.5)
    @naming_image_label = Gtk::Label.new(_('Single file image:')) ; @naming_image_label.set_alignment(0.0, 0.5)
    @example_label =Gtk::Label.new('') ; @example_label.set_alignment(0.0, 0.5) ; @example_label.wrap = true
    @expander100 = Gtk::Expander.new(_('Show options for "File naming scheme"'))
    @example_label_shows = 'normal'
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
    @frame100 = newFrame(_('File naming scheme'), child=@table100)
  end

  def showFileNormal
    backupPrefsBeforeExampleLabelUpdate()
    @example_label.text = _("Example file name: ") +
      Preferences.showFilenameNormal( @basedirEntry.text, @namingNormalEntry.text)
    @example_label_shows = 'normal'
    restorePrefsAfterExampleLabelUpdate()
  end
  
  def showFileVarious
    backupPrefsBeforeExampleLabelUpdate()
    @example_label.text = _("Example file name: ") +
      Preferences.showFilenameVarious(@basedirEntry.text, @namingVariousEntry.text)
    @example_label_shows = 'various'
    restorePrefsAfterExampleLabelUpdate()
  end
  
  def showFileImage
    backupPrefsBeforeExampleLabelUpdate()
    @example_label.text = _("Example file name: ") +
      Preferences.showFilenameVarious(@basedirEntry.text, @namingImageEntry.text)
    @example_label_shows = 'image'
    restorePrefsAfterExampleLabelUpdate()
  end

  def updateExampleLabel
    if @example_label_shows == 'various'
      showFileVarious()
    elsif @example_label_shows == 'image'
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
    @frame110 = newFrame(_('Programs of choice'), child=@table110)
  end

#Small table for debugging
#Verbose mode	| debug mode
  def buildFrameDebugOptions # Debug options frame
    @table120 = newTable(rows=1, columns=2)
#creating objects and packing them
    @verbose = Gtk::CheckButton.new(_('Verbose mode'))
    @debug = Gtk::CheckButton.new(_('Debug mode'))
    @table120.attach(@verbose, 0,1,0,1,Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::SHRINK)
    @table120.attach(@debug, 1,2,0,1,Gtk::AttachOptions::FILL|Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::SHRINK)
    @frame120 = newFrame(_('Debug options'), child=@table120)
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

