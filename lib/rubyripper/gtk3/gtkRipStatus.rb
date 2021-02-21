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

# RipStatus handles the rubyripper window while ripping.
# Notice that the left part of the gui with the icons is not in this class

class RipStatus
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :textview, :display

  def initialize(gui)
    @ui = gui
    createObjects()
    packObjects()
    reset() #reset to default text
  end

  # Show the update in progress of the ripping/encoding
  def updateProgress(type, value)
    progress = "%.3g" % (value * 100)
    if type == 'encoding'
      @encBar.text = _("Encoding progress %s %%") % [progress]
      @encBar.fraction = value
    else
      @ripBar.text = _("Ripping progress %s %%") % progress
      @ripBar.fraction = value
    end
  end

  # Show the new text in the status window
  def logChange(text)
    start_iter, end_iter = @textview.buffer.bounds
    @textview.buffer.insert(end_iter, text)
    @ui.update("scroll_to_end")
  end

  def scrollToEnd
    start_iter, end_iter = @textview.buffer.bounds
    @mark = @textview.buffer.create_mark(nil, end_iter, true) unless @mark
    @textview.buffer.move_mark(@mark, end_iter)
    @textview.scroll_mark_onscreen(@mark)
  end

  def createObjects
    @textview = Gtk::TextView.new
    @textview.editable = false
    @textview.wrap_mode = Gtk::WrapMode::WORD
    
    @scrolledWindow = Gtk::ScrolledWindow.new
    @scrolledWindow.set_policy(Gtk::PolicyType::NEVER, Gtk::PolicyType::AUTOMATIC)
    @scrolledWindow.border_width = 7
    @scrolledWindow.add(@textview)

    @encBar = Gtk::ProgressBar.new
    @ripBar = Gtk::ProgressBar.new
    @encBar.pulse_step = 0.01
    @ripBar.pulse_step = 0.01
    @encBar.show_text = true
    @ripBar.show_text = true

    @hbox1 = Gtk::Box.new(:horizontal)
    @hbox1.homogeneous = true
    @vbox1 = Gtk::Box.new(:vertical)
    @vbox1.border_width = 5

    @label1 = Gtk::Label.new
    @label1.set_markup(_("<b>Ripping status</b>"))
    @display = Gtk::Frame.new
    @display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
    @display.label_widget = @label1
    @display.border_width = 5
  end

  def packObjects
    @hbox1.pack_start(@ripBar, :expand => true, :fill => true, :padding => 5)
    @hbox1.pack_start(@encBar, :expand => true, :fill => true, :padding => 5)
    @vbox1.pack_start(@scrolledWindow, :expand => true, :fill => true)
    @vbox1.pack_start(@hbox1, :expand => false, :fill => false)
    @display.add(@vbox1)
  end

  # load default values
  def reset
    @encBar.text = _('Not yet started (0%)')
    @ripBar.text = _('Not yet started (0%)')
    @encBar.fraction = 0.0
    @ripBar.fraction = 0.0
    @textview.buffer.text = ""
  end
end

