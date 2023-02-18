#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/preferences/main'
require 'rubyripper/system/execute'

# Summary handles the rubyripper window while displaying the summary of a rip.
# Notice that the left part of the gui with the icons is not in this class
class GtkSummary
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  def initialize(scheme, summary, succes)
    @prefs = Preferences::Main.instance
    @exec = Execute.new
    showMainResult(succes)
    buildSummary(summary)
    buildOpenLogButton()
    buildOpenDirButton()
    setSignals(scheme)
    assemblePage()
  end

  def showMainResult(succes)
    if succes == true
      @label1 = Gtk::Label.new(_("The rip has succesfully finished.\nA short summary is shown below."))
      @image1 = Gtk::Image.new(:stock => Gtk::Stock::DIALOG_INFO, :size => Gtk::IconSize::DIALOG)
    else
      @label1 = Gtk::Label.new(_("The rip had some problems.\nA short summary is shown below."))
      @image1 = Gtk::Image.new(:stock => Gtk::Stock::DIALOG_ERROR, :size => Gtk::IconSize::DIALOG)
    end
  end

  def buildSummary(summary)
    @hbox1 = Gtk::Box.new(:horizontal)
    [@image1, @label1].each{|object| @hbox1.pack_start(object)}
    @hbox1.border_width = 10
    @separator1 = Gtk::Separator.new(:horizontal)

    @textview = Gtk::TextView.new
    @textview.editable = false
    @scrolled_window = Gtk::ScrolledWindow.new
    @scrolled_window.set_policy(Gtk::PolicyType::NEVER, Gtk::PolicyType::NEVER)
    @scrolled_window.border_width = 7
    @scrolled_window.add(@textview)
    @textview.buffer.insert(@textview.buffer.end_iter, summary)
  end

  def buildOpenLogButton
    @button1 = Gtk::Button.new()
    @label2 = Gtk::Label.new(_("Open log file"))
    @image2 = Gtk::Image.new(:stock => Gtk::Stock::EXECUTE, :size => Gtk::IconSize::LARGE_TOOLBAR)
    @hbox2 = Gtk::Box.new(:horizontal)
    [@image2, @label2].each{|object| @hbox2.pack_start(object)}
    @button1.add(@hbox2)
  end

  def buildOpenDirButton
    # assemble button 2
    @button2 = Gtk::Button.new()
    @label3 = Gtk::Label.new(_("Open directory"))
    @image3 = Gtk::Image.new(:stock => Gtk::Stock::OPEN, :size => Gtk::IconSize::LARGE_TOOLBAR)
    @hbox3 = Gtk::Box.new(:horizontal)
    [@image3, @label3].each{|object| @hbox3.pack_start(object)}
    @button2.add(@hbox3)
  end

  def setSignals(scheme)
    @button1.signal_connect("released") do
      Thread.new{@exec.launch("#{@prefs.editor} \"#{File.join(scheme.getDir(), "ripping.log")}\"")}
    end

    @button2.signal_connect("released") do
      Thread.new{@exec.launch("#{@prefs.filemanager} \"#{scheme.getDir()}\"")}
    end
  end

  def assemblePage
    @hbox4 = Gtk::Box.new(:horizontal, 5) #put the two buttons in a box
    @hbox4.homogeneous=true
    [@button1, @button2].each{|object| @hbox4.pack_start(object)}

    @vbox1 = Gtk::Box.new(:vertical, 10)
    @vbox1.pack_start(@hbox1, :expand => false, :fill => false)
    @vbox1.pack_start(@separator1, :expand => false, :fill => false)
    @vbox1.pack_start(@scrolled_window, :expand => false, :fill => false) #maximize the space for displaying the tracks
    @vbox1.pack_start(@hbox4, :expand => false, :fill => false)

    @display = Gtk::Frame.new(_("Ripping and encoding is finished"))
    @display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
    @display.border_width = 5
    @display.add(@vbox1)
  end
end
