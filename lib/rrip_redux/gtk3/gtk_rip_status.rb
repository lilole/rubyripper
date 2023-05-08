# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

module RripRedux
module Gtk3
  # RipStatus handles the rubyripper window while ripping.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class GtkRipStatus
    include GetText; GetText.bindtextdomain("rrip_redux")
    include GtkConstants

    attr_reader :display, :enc_bar, :hbox1, :label1, :mark, :rip_bar, :scrolled_window, :textview, :ui, :vbox1

    def initialize(gui)
      @ui = gui
      create_objects
      pack_objects
      reset
    end

    def update_progress(type, value)
      progress = "%3.1g" % (value.to_f * 100)
      if type == "encoding"
        enc_bar.text = _("Encoding progress %s %%") % progress
        enc_bar.fraction = value
      else
        rip_bar.text = _("Ripping progress %s %%") % progress
        rip_bar.fraction = value
      end
    end

    # Show the new text in the status window.
    #
    def log_change(text)
      start_iter, end_iter = textview.buffer.bounds
      textview.buffer.insert(end_iter, text)
      ui.update("scroll_to_end")
    end

    def scroll_to_end
      start_iter, end_iter = textview.buffer.bounds
      @mark ||= textview.buffer.create_mark(nil, end_iter, true)
      textview.buffer.move_mark(mark, end_iter)
      textview.scroll_mark_onscreen(mark)
    end

    def reset
      enc_bar.text = _("Not yet started (0%)")
      enc_bar.fraction = 0.0

      rip_bar.text = _("Not yet started (0%)")
      rip_bar.fraction = 0.0

      textview.buffer.text = ""
    end

  private

    def create_objects
      @textview        = Gtk::TextView.new
      @scrolled_window = Gtk::ScrolledWindow.new
      @enc_bar         = Gtk::ProgressBar.new
      @rip_bar         = Gtk::ProgressBar.new
      @hbox1           = Gtk::Box.new(:horizontal)
      @vbox1           = Gtk::Box.new(:vertical)
      @label1          = Gtk::Label.new
      @display         = Gtk::Frame.new

      textview.editable = false
      textview.wrap_mode = gWORD

      scrolled_window.set_policy(gNEVER, gAUTOMATIC)
      scrolled_window.border_width = 7
      scrolled_window.add(textview)

      enc_bar.pulse_step = 0.01
      enc_bar.show_text = true

      rip_bar.pulse_step = 0.01
      rip_bar.show_text = true

      hbox1.homogeneous = true
      vbox1.border_width = 5
      label1.set_markup(_("<b>Ripping status</b>"))

      display.set_shadow_type(gETCHED_IN)
      display.label_widget = label1
      display.border_width = 5
    end

    def pack_objects
      hbox1.pack_start(rip_bar,         expand: true,  fill: true, padding: 5)
      hbox1.pack_start(enc_bar,         expand: true,  fill: true, padding: 5)
      vbox1.pack_start(scrolled_window, expand: true,  fill: true)
      vbox1.pack_start(hbox1,           expand: false, fill: false)

      display.add(vbox1)
    end
  end
end
end
