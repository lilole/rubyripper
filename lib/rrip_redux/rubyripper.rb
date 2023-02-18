#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012  Bouke Woudstra (boukewoudstra@gmail.com)
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

# The main program is launched from the class Rubyripper
class Rubyripper
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :outputDir, :fileScheme, :log

  # * userInterface = the user interface object (with the update function)
  # * disc = the disc object
  # * trackSelection = an array with selected tracks
  def initialize(userInterface, disc, trackSelection, file=nil, prefs=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @ui = userInterface
    @disc = disc
    @trackSelection = Array.new(trackSelection) # make a copy, it might be modified to include hidden track
    @file = file ? file : FileAndDir.instance()
    # if enabled and hidden track exist, add the track 0 to the track selection
    @trackSelection.unshift(0) if @prefs.ripHiddenAudio && @disc.getStartSector(0)
    puts "DEBUG: trackselection = #{@trackSelection}" if @prefs.debug
  end

  # check if all is ready to go
  def checkConfiguration
    require 'rubyripper/fileScheme'
    @fileScheme = FileScheme.new(@disc, @trackSelection)
    @fileScheme.prepare()

    require 'rubyripper/checkConfigBeforeRipping'
    return CheckConfigBeforeRipping.new(@ui, @disc, @trackSelection, @fileScheme).result
  end

  # check the existence of the output dir
  def dirStillAvailable
    @fileScheme.dir.values.each{|dir| return false if @file.exists?(dir) }
    return true
  end

  # do some neccesary preparation and start the ripping
  def startRip
    if dirStillAvailable
      @fileScheme.createFileAndDirs()
      autofixCommonMistakes()
      calculatePercentageUpdateForProgressbar()
      createHelpObjects()
      @log.start() # TODO find a better name for the class and function
      @rippingInfoAtStart.show()
      waitForCuesheet() if @prefs.createCue
      @ripper.startTheRip()
    else
      @ui.update("dir_exists", @fileScheme.dir.values[0])
    end
    # @disc.md.saveChanges() # TODO update the local freedb file
  end

  def createHelpObjects
    # create the logfile + handle user interface updates + summary of errors
    require 'rubyripper/log'
    @log = Log.new(@disc, @fileScheme, @ui, @updatePercForEachTrack)

    # show basic info for current rip and settings
    require 'rubyripper/rippingInfoAtStart'
    @rippingInfoAtStart = RippingInfoAtStart.new(@disc, @log, @trackSelection)

    # to execute the encoding
    require 'rubyripper/encode'
    @encoding = Encode.new(@log, @trackSelection, @disc, @fileScheme)

    # to execute the ripping
    require 'rubyripper/secureRip'
    @ripper = SecureRip.new(@trackSelection, @disc, @fileScheme, @log, @encoding)
  end

  def waitForCuesheet
    @disc.finishExtendedTocScan(@log)
    @prefs.codecs.each{|codec| @file.write(@fileScheme.getCueFile(codec), @disc.getCuesheet(codec, fileScheme))}
  end

  def calculatePercentageUpdateForProgressbar()
    @updatePercForEachTrack = Hash.new()
    totalSectors = 0.0 # It can be that the user doesn't want to rip all tracks, so calculate it
    @trackSelection.each{|track| totalSectors += @disc.getLengthSector(track)} #update totalSectors
    @trackSelection.each{|track| @updatePercForEachTrack[track] = @disc.getLengthSector(track) / totalSectors}
  end

  def autofixCommonMistakes
    freedbHostnameAndUsernameCanNotBeEmpty()
    flacIsNotAllowedToDeleteInputFile() if @prefs.flac
    #repairOtherPrefs() if @prefs.other # TODO: See method comment
    rippingErrorSectorsMustAtLeastEqualRippingNormalSectors()
  end

  # otherwise the freedb server returns an error
  def freedbHostnameAndUsernameCanNotBeEmpty
    if @prefs.username.strip().empty?
      @prefs.username = 'anonymous'
    end

    if @prefs.hostname.strip().empty?
      @prefs.hostname = 'my_secret.com'
    end
  end

  # filter out encoding flags that do non-encoding tasks
  def flacIsNotAllowedToDeleteInputFile
    @prefs.settingsFlac = @prefs.settingsFlac.gsub(' --delete-input-file', '')
  end

  # TODO: Delete this? It does not seem to be needed now, as each `%x` format
  #       string value is automatically wrapped in quotes at parse time.
  #def repairOtherPrefs
  #  copyString = ""
  #  lastChar = ""
  #
  #  #first remove all double quotes. then iterate over each char
  #  @prefs.settingsOther.delete('"').split(//).each do |char|
  #    if char == '%' # prepend double quote before %
  #      copyString << '"' + char
  #    elsif lastChar == '%' # append double quote after %char
  #      copyString << char + '"'
  #    else
  #      copyString << char
  #    end
  #    lastChar = char
  #  end
  #
  #  # above won't work for various artist
  #  copyString.gsub!('"%v"a', '"%va"')
  #
  #  @prefs.settingsOther = copyString
  #  puts @prefs.settingsOther if @prefs.debug
  #end

  def rippingErrorSectorsMustAtLeastEqualRippingNormalSectors()
    if @prefs.reqMatchesErrors < @prefs.reqMatchesAll
      @prefs.reqMatchesErrors = @prefs.reqMatchesAll
    end
  end

  # the user wants to abort the ripping
  def cancelRip
    puts "User aborted current rip"
    `killall cdrdao`
    @encoding.cancelled = true if @encoding != nil
    @encoding = nil
    @ripping.cancelled = true if @ripping != nil
    @ripping = nil
    `killall cdparanoia` # kill any rip that is already started
  end

  def summary
    return @log.short_summary
  end

  def postfixDir
    @fileScheme.postfixDir()
  end

  def overwriteDir
    @fileScheme.overwriteDir()
  end
end
