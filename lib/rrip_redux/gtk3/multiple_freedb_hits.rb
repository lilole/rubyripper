# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

module RripRedux
module Gtk3
  # MultipleFreedbHits handles the app window while displaying the dialog
  # when multiple freedb hits are offered to the user.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class MultipleFreedbHits
    include GetText; GetText.bindtextdomain("rrip_redux")

    attr_reader :button1, :combobox, :display, :hbox1, :hbox2, :hbox3, :hbox4, :image1, :image2, :label1, :label2,
      :separator1, :vbox1

    def initialize(metadata, main_instance)
      @label1 = Gtk::Label.new(_("The gnudb server reports multiple hits.\nWhich one would you prefer?"))
      @image1 = Gtk::Image.new(stock: Gtk::Stock::DIALOG_QUESTION, size: Gtk::IconSize::DIALOG)
      @hbox1 = Gtk::Box.new(:horizontal)
      [image1, label1].each { |object| hbox1.pack_start(object) }

      @combobox = Gtk::ComboBoxText.new
      metadata.get_choices.each { |freedb_hit| combobox.append_text(freedb_hit) }
      combobox.active = 0
      @separator1 = Gtk::Separator.new(:horizontal)
      @hbox2 = Gtk::Box.new(:horizontal)
      hbox2.pack_start(combobox, expand: true, fill: true, padding: 5)

      @button1 = Gtk::Button.new
      @label2 = Gtk::Label.new(_("Ok"))
      @image2 = Gtk::Image.new(stock: Gtk::Stock::OK, size: Gtk::IconSize::LARGE_TOOLBAR)
      @hbox3 = Gtk::Box.new(:horizontal)
      [image2, label2].each { |object| hbox3.pack_start(object, expand: false, fill: false, padding: 10) }
      button1.add(hbox3)
      @hbox4 = Gtk::Box.new(:horizontal)
      hbox4.pack_start(button1, expand: true, fill: false)

      @vbox1 = Gtk::Box.new(:vertical)
      @vbox1.border_width = 10
      [hbox1, hbox2, separator1, hbox4].each do |object|
        vbox1.pack_start(object, expand: false, fill: false, padding: 10)
      end

      @display = Gtk::Frame.new(_("Multiple hits found..."))
      display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
      display.border_width = 5
      display.add(vbox1)
      button1.signal_connect("released") do
        metadata.choose(combobox.active)
        main_instance.update("scan_disc_finished")
      end
    end
  end
end
end
