#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2013  Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'

# some sanity checks before the ripping starts
class CheckConfigBeforeRipping
  # * userInterface = the user interface object (with the update function)
  # * disc = the disc object
  # * trackSelection = an array with selected tracks
  def initialize(userInterface, disc, trackSelection, fileScheme, file=nil, prefs=nil, deps=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @ui = userInterface
    @disc = disc
    @trackSelection = trackSelection
    @fileScheme = fileScheme
    @file = file ? file : FileAndDir.instance()
    @deps = deps ? deps : Dependency.instance()
    @errors = Array.new
  end

  # Give the result for the checks
  def result
    checkPreferences()
    checkUserInterface()
    checkDisc()
    checkTrackSelection()
    checkBinaries()
    checkOutputLocationWritable()
    return @errors
  end

private
  def addError(code, parameters=nil)
    @errors << [code, parameters]
  end

  def checkPreferences
    checkMinOneCodec()
    checkCuesheetPossible()
  end

  def checkMinOneCodec()
    addError(:noCodecSelected) if @prefs.codecs.empty?
  end
  
  def checkCuesheetPossible
    addError(:cdrdaoNotFound) unless @deps.installed?('cdrdao')
  end

  def checkUserInterface
    addError(:noValidUserInterface) unless @ui.respond_to?(:update)
  end

  def checkDisc
    addError(:noDiscInDrive, @prefs.cdrom) if @disc.status != 'ok'
  end

  # notice that image rips don't require track selection
  def checkTrackSelection
    if !@prefs.image && @trackSelection.empty?
      addError(:noTrackSelection)
    end
  end

  def checkBinaries
    isFound?('cdparanoia')
    isFound?('flac') if @prefs.flac
    isFound?('oggenc') if @prefs.vorbis
    isFound?('lame') if @prefs.mp3
    isFound?('neroAacEnc') if @prefs.nero
    isFound?('fdkaac') if @prefs.fraunhofer
    isFound?('wavpack') if @prefs.wavpack
    isFound?('opusenc') if @prefs.opus
    isFound?('normalize', 'normalize-audio') if @prefs.normalizer == 'normalize'

    if @prefs.normalizer == 'replaygain'
      isFound?('metaflac') if @prefs.flac
      isFound?('vorbisgain') if @prefs.vorbis
      isFound?('mp3gain') if @prefs.mp3
      isFound?('wavegain') if @prefs.wav
      isFound?('aacgain') if @prefs.nero || @prefs.fraunhofer
      isFound?('wvgain') if @prefs.wavpack
    end
  end

  def isFound?(binary, alternativeBinary=nil)
    if !@deps.installed?(binary) &&
        (alternativeBinary == nil ||
        (alternativeBinary != nil && !@deps.installed?(alternativeBinary)))
      addError(:binaryNotFound, binary.capitalize)
    end
  end
  
  def checkOutputLocationWritable
    @fileScheme.dir.values.each do |location|
      unless @file.writable?(location)
        addError(:dirNotWritable, location)
      end
    end
  end
end

		#TODO
		#if (!@prefs['cd'].tocStarted || @prefs['cd'].tocFinished)
		#	temp = AccurateScanDisc.new(@prefs, @prefs['instance'], '', true)
		#	if @prefs['cd'].freedbString != temp.freedbString || @prefs['cd'].playtime != temp.playtime
		#		@error = ["error", _("The Gui doesn't match inserted cd. Please press Scan Drive first.")]
 		#		return false
		#	end
		#end

    #TODO
		# update the ripping prefs for a hidden audio track if track 1 is selected
		#if @prefs['cd'].getStartSector(0) && @prefs['tracksToRip'][0] == 1
		#	@prefs['tracksToRip'].unshift(0)
		#end
