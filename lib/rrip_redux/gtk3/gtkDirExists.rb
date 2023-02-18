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

# DirExists handles the rubyripper window while in the dialog "Dir exists".
# This dialog is shown when you try to rip, but the dir already exists.
# Notice that the left part of the gui with the icons is not in this class

class GtkDirExists
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  def initialize(gui, rubyripper, dirname)
    @label = Gtk::Label.new(_("The directory %s already exists.\n\nWhat do you want rubyripper to do?") % [dirname])
    @label.wrap = true
    @image = Gtk::Image.new(:stock => Gtk::Stock::DIALOG_QUESTION, :size => Gtk::IconSize::DIALOG)
  
    @infobox = Gtk::Box.new(:horizontal)
    @infobox.add(@image) ; @infobox.add(@label)
    @separator = Gtk::Separator.new(:horizontal)

    @buttons = [Gtk::Button.new, Gtk::Button.new, Gtk::Button.new]
    @labels = [Gtk::Label.new(_("Cancel rip")),
               Gtk::Label.new(_("Delete existing\ndirectory")),
               Gtk::Label.new(_("Auto rename\ndirectory"))]
    @images = [Gtk::Image.new(:stock => Gtk::Stock::CANCEL, :size => Gtk::IconSize::LARGE_TOOLBAR),
               Gtk::Image.new(:stock => Gtk::Stock::CLEAR, :size => Gtk::IconSize::LARGE_TOOLBAR),
               Gtk::Image.new(:stock => Gtk::Stock::OK, :size => Gtk::IconSize::LARGE_TOOLBAR)]
    @hboxes = [Gtk::Box.new(:horizontal), Gtk::Box.new(:horizontal), Gtk::Box.new(:horizontal)]
    @buttonbox = Gtk::Box.new(:horizontal)

    3.times do |index|
      @hboxes[index].pack_start(@images[index], :expand => false, :fill => false) #pack the image + label into a hbox
      @hboxes[index].pack_start(@labels[index], :expand => false, :fill => false)
      @buttons[index].add(@hboxes[index]) #put the hbox into the button
      @buttonbox.pack_start(@buttons[index], :expand => false, :fill => false, :padding => 10) #put the buttons into a hbox
    end

    @buttons[0].signal_connect("released") {gui.showDisc()}
    @buttons[1].signal_connect("released") {rubyripper.overwriteDir() ; gui.continueRip() }
    @buttons[2].signal_connect("released") {rubyripper.postfixDir() ; gui.continueRip() }

    @vbox = Gtk::Box.new(:vertical)
    @vbox.border_width = 10
    [@infobox, @separator, @buttonbox].each{|object| @vbox.pack_start(object, :expand => false, :fill => false, :padding => 10)}
    
    @display = Gtk::Frame.new(_("Directory already exists...")) # will contain the above
    @display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
    @display.border_width = 5
    @display.add(@vbox)
  end
end
