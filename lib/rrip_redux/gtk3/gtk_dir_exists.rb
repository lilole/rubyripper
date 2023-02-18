# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

module RripRedux
module Gtk3
  # DirExists handles the rrip_redux window while in the dialog "Dir exists".
  # This dialog is shown when you try to rip, but the dir already exists.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class GtkDirExists
    include GetText; GetText.bindtextdomain("rrip_redux")

    attr_reader :buttonbox, :buttons, :display, :hboxes, :image, :infobox, :label, :labels, :separator, :vbox

    def initialize(gui, rrip_redux, dirname)
      @label = Gtk::Label.new(_("The directory %s already exists.\n\nWhat do you want to do?") % [dirname])
      label.wrap = true
      @image = Gtk::Image.new(stock: Gtk::Stock::DIALOG_QUESTION, size: Gtk::IconSize::DIALOG)

      @infobox = Gtk::Box.new(:horizontal)
      infobox.add(image)
      infobox.add(label)
      @separator = Gtk::Separator.new(:horizontal)

      @buttons = [Gtk::Button.new, Gtk::Button.new, Gtk::Button.new]
      @labels = [
        Gtk::Label.new(_("Cancel rip")),
        Gtk::Label.new(_("Delete existing\ndirectory")),
        Gtk::Label.new(_("Auto rename\ndirectory"))
      ]
      @images = [
        Gtk::Image.new(:stock => Gtk::Stock::CANCEL, :size => Gtk::IconSize::LARGE_TOOLBAR),
        Gtk::Image.new(:stock => Gtk::Stock::CLEAR, :size => Gtk::IconSize::LARGE_TOOLBAR),
        Gtk::Image.new(:stock => Gtk::Stock::OK, :size => Gtk::IconSize::LARGE_TOOLBAR)
      ]
      @hboxes = [Gtk::Box.new(:horizontal), Gtk::Box.new(:horizontal), Gtk::Box.new(:horizontal)]
      @buttonbox = Gtk::Box.new(:horizontal)

      3.times do |index|
        hboxes[index].pack_start(images[index], expand: false, fill: false)
        hboxes[index].pack_start(labels[index], expand: false, fill: false)
        buttons[index].add(hboxes[index])
        buttonbox.pack_start(buttons[index], expand: false, fill: false, padding: 10)
      end

      buttons[0].signal_connect("released") { gui.show_disc }
      buttons[1].signal_connect("released") { rrip_redux.overwrite_dir; gui.continue_rip }
      buttons[2].signal_connect("released") { rrip_redux.postfix_dir;   gui.continue_rip }

      @vbox = Gtk::Box.new(:vertical)
      vbox.border_width = 10

      [infobox, separator, buttonbox].each do |object|
        vbox.pack_start(object, expand: false, fill: false, padding: 10)
      end

      @display = Gtk::Frame.new(_("Directory already exists..."))
      display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
      display.border_width = 5
      display.add(vbox)
    end
  end
end
end
