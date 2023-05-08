# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

#require 'rubyripper/preferences/main'
#require 'rubyripper/system/execute'

module RripRedux
module Gtk3
  # Summary handles the rubyripper window while displaying the summary of a rip.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class GtkSummary
    include GetText; GetText.bindtextdomain("rrip_redux")
    include GtkConstants

    attr_reader :button1, :button2,
      :display, :exec,
      :hbox1, :hbox2, :hbox3, :hbox4,
      :image1, :image2, :image3,
      :label1, :label2, :label3,
      :prefs, :scrolled_window, :separator1, :textview,
      :vbox1

    def initialize(scheme, summary, success)
      @prefs = RripRedux::Preferences::Main.instance
      @exec  = RripRedux::System::Execute.new
      show_main_result(success)
      build_summary(summary)
      build_open_log_button
      build_open_dir_button
      set_signals(scheme)
      assemble_page
    end

  private

    def show_main_result(success)
      if success
        @label1 = Gtk::Label.new(_("The rip has succesfully finished.\nA short summary is shown below."))
        @image1 = Gtk::Image.new(stock: gDIALOG_INFO, size: gDIALOG)
      else
        @label1 = Gtk::Label.new(_("The rip had some problems.\nA short summary is shown below."))
        @image1 = Gtk::Image.new(stock: gDIALOG_ERROR, size: gDIALOG)
      end
    end

    def build_summary(summary)
      @hbox1           = Gtk::Box.new(:horizontal)
      @textview        = Gtk::TextView.new
      @separator1      = Gtk::Separator.new(:horizontal)
      @scrolled_window = Gtk::ScrolledWindow.new

      hbox1.border_width = 10
      textview.editable = false
      scrolled_window.set_policy(gNEVER, gNEVER)
      scrolled_window.border_width = 7
      scrolled_window.add(textview)
      textview.buffer.insert(textview.buffer.end_iter, summary)

      [image1, label1].each { |object| hbox1.pack_start(object) }
    end

    def build_open_log_button
      @button1 = Gtk::Button.new
      @label2  = Gtk::Label.new(_("Open log file"))
      @image2  = Gtk::Image.new(stock: gEXECUTE, size: gLARGE_TOOLBAR)
      @hbox2   = Gtk::Box.new(:horizontal)

      [image2, label2].each { |object| hbox2.pack_start(object) }

      button1.add(hbox2)
    end

    def build_open_dir_button
      @button2 = Gtk::Button.new
      @label3  = Gtk::Label.new(_("Open directory"))
      @image3  = Gtk::Image.new(stock: gOPEN, size: gLARGE_TOOLBAR)
      @hbox3   = Gtk::Box.new(:horizontal)

      [image3, label3].each { |object| hbox3.pack_start(object) }

      button2.add(hbox3)
    end

    def set_signals(scheme)
      button1.signal_connect("released") do
        Thread.new { exec.launch("#{prefs.editor} '#{File.join(scheme.get_dir, "ripping.log")}'") }
      end

      button2.signal_connect("released") do
        Thread.new { exec.launch("#{prefs.filemanager} '#{scheme.get_dir}'") }
      end
    end

    def assemble_page
      @hbox4   = Gtk::Box.new(:horizontal, 5) # Put the two buttons in a box
      @vbox1   = Gtk::Box.new(:vertical, 10)
      @display = Gtk::Frame.new(_("Ripping and encoding is finished"))

      hbox4.homogeneous = true

      [button1, button2].each { |object| hbox4.pack_start(object) }

      vbox1.pack_start(hbox1,           expand: false, fill: false)
      vbox1.pack_start(separator1,      expand: false, fill: false)
      vbox1.pack_start(scrolled_window, expand: false, fill: false) # Maximize the space for displaying the tracks
      vbox1.pack_start(hbox4,           expand: false, fill: false)

      display.set_shadow_type(gETCHED_IN)
      display.border_width = 5
      display.add(vbox1)
    end
  end
end
end
