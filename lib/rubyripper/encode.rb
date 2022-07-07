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

# The Encode class is responsible the threads for the diverse codecs.

require 'thread' # for the sized queue object
require 'monitor' # for the monitor object

require 'rubyripper/codecs/main'
require 'rubyripper/system/fileAndDir'
require 'rubyripper/system/dependency'
require 'rubyripper/system/execute'
require 'rubyripper/preferences/main'

class Encode
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_writer :cancelled

  def initialize(log, trackSelection, disc, scheme, file=nil, deps=nil, exec=nil, prefs=nil)
    @log = log
    @trackSelection = trackSelection
    @scheme = scheme
    @file = file ? file : FileAndDir.instance
    @deps = deps ? deps : Dependency.instance
    @exec = exec ? exec : Execute.new()
    @prefs = prefs ? prefs : Preferences::Main.instance
    @codecs = [] ; @prefs.codecs.each{|codec| @codecs << Codecs::Main.new(codec, disc, scheme)}
    setHelpVariables()
  end

  def setHelpVariables
    @cancelled = false
    @progress = 0.0
    @threads = []
    @queue = SizedQueue.new(@prefs.maxThreads) if @prefs.maxThreads != 0
    @lock = Monitor.new

    # all encoding tasks are saved here, to determine when to delete a wav
    @tasks = Hash.new
    if @prefs.image
      @tasks['image'] = getCopyOfPrefsCodecs
    else
      @trackSelection.each{|track| @tasks[track] = getCopyOfPrefsCodecs}
    end
  end

  def getCopyOfPrefsCodecs
    pref_codecs = [] ; @prefs.codecs.each{|codec| pref_codecs << codec }
    pref_codecs
  end

  # is called when a track is ripped succesfully
  def addTrack(track=nil)
    startEncoding(track) unless waitingForNormalizeToFinish(track)
  end

  # encode track when normalize is finished
  def startEncoding(track=nil)
    # mark the progress bar as being started
    @log.updateEncodingProgress() if track == @trackSelection[0] || @prefs.image
    return false if @cancelled != false

    @codecs.each do |codec|
      if @prefs.maxThreads == 0 || @prefs.image
        encodeTrack(codec, track)
      else
        puts "DEBUG: Adding track #{track} (#{codec.name}) to the queue.." if @prefs.debug
        @queue << 1 # add a value to the queue, if full wait here.
        @threads << Thread.new do
          encodeTrack(codec, track)
          puts "DEBUG: Removing track #{track} (#{codec.name}) from the queue.." if @prefs.debug
          @queue.shift() # move up in the queue to the first waiter
        end
      end
    end

    #give the signal we're finished
    if (@prefs.image || track == @trackSelection[-1]) && @cancelled == false
      @threads.each{|thread| thread.join()}
      @log.finished()
    end
  end

  # respect the normalize setting
  def waitingForNormalizeToFinish(track=nil)
    return false if @prefs.normalizer != 'normalize'

    binary = getNormalizeBinary()
    return false unless binary.class == String

    if @prefs.gain == 'track' || @prefs.image
      command = "#{binary} \"#{@scheme.getTempFile(track, 1)}\""
      @exec.launch(command)
      waiting = false
    elsif @prefs.gain == 'album' && @trackSelection[-1] != track
      waiting = true
    elsif @prefs.gain == 'album' && @trackSelection[-1] == track
      command = "#{binary} -b \"#{File.join(@scheme.getTempDir(),'*.wav')}\""
      @exec.launch(command)
      # now the wavs are altered, the encoding can start
      @trackSelection.each{|track| startEncoding(track)}
      waiting = true
    end
    return waiting
  end

  # the binary can differ between distributions
  def getNormalizeBinary
    if @deps.installed?('normalize')
      return 'normalize'
    elsif @deps.installed?('normalize-audio')
      return 'normalize-audio'
    else
      puts "DEBUG: No normalize binary found, normalizing is skipped.." if @prefs.debug
      return false
    end
  end

  # call the specific codec function for the track and apply replaygain if desired
  def encodeTrack(codec, track=nil)
    @log.encodingErrors = true if @exec.launch(codec.command(track)).empty?

    if @prefs.normalizer == "replaygain" && @prefs.gain == "track"
      @exec.launch(codec.replaygain(track))
    end

    @exec.launch(codec.setTagsAfterEncoding(track))

    @lock.synchronize do
      key = @prefs.image ? 'image' : track
      @tasks[key].delete(codec.name)
      @file.delete(@scheme.getTempFile(track)) if @tasks[key].empty?
      @log.updateEncodingProgress(track, @codecs.size)
    end

    if @prefs.normalizer == "replaygain" && @prefs.gain == "album"
      @exec.launch(codec.replaygainAlbum()) unless @tasks.values.flatten.include?(codec.name)
    end
  end
end
