# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

require "rexml/document"

module RripRedux
module Gtk3
  # MultipleMusicBraizHits handles the window while displaying the dialog
  # when multiple musicbrainz hits are offered to the user.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class MultipleMusicBrainzHits
    include GetText; GetText.bindtextdomain("rrip_redux")

    attr_reader :barcode_value, :button1, :choices, :combobox, :country_value, :date_value, :desc_value, :display,
      :hbox1, :hbox3, :hbox4, :image1, :image2, :label1, :label2, :packaging_value, :release_info_table,
      :separator1, :status_value, :title_vale, :vbox1, :vbox2

    def initialize(metadata, main_instance)
      @label1 = Gtk::Label.new(_("The musicbrainz server reports multiple releases.\nWhich one would you prefer?"))
      @image1 = Gtk::Image.new(stock: Gtk::Stock::DIALOG_QUESTION, size: Gtk::IconSize::DIALOG)
      @hbox1 = Gtk::Box.new(:horizontal)
      [image1, label1].each { |object| hbox1.pack_start(object) }

      @choices = metadata.get_choices
      @combobox = Gtk::ComboBoxText.new
      metadata.get_choices.each { |release| combobox.append_text(release.attribute("id").to_s) }
      create_release_info_table
      combobox.signal_connect("changed") { update_release_info_table }
      combobox.active = 0

      @vbox2 = Gtk::Box.new(:vertical)
      [combobox, release_info_table].each do |object|
        vbox2.pack_start(object, expand: true, fill: true, padding: 5)
      end

      @separator1 = Gtk::Separator.new(:horizontal)
      @button1 = Gtk::Button.new
      @label2 = Gtk::Label.new(_("Ok"))
      @image2 = Gtk::Image.new(stock: Gtk::Stock::OK, size: Gtk::IconSize::LARGE_TOOLBAR)
      @hbox3 = Gtk::Box.new(:horizontal)
      [image2, label2].each do |object|
        hbox3.pack_start(object, expand: false, fill: false, padding: 10)
      end
      button1.add(hbox3)

      @hbox4 = Gtk::Box.new(:horizontal)
      hbox4.pack_start(button1, expand: true, fill: false)

      @vbox1 = Gtk::Box.new(:vertical)
      vbox1.border_width = 10
      [hbox1, vbox2, separator1, hbox4].each do |object|
        vbox1.pack_start(object, expand: false, fill: false, padding: 10)
      end

      @display = Gtk::Frame.new(_("Multiple releases found..."))
      display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
      display.border_width = 5
      display.add(vbox1)
      button1.signal_connect("released") do
        metadata.choose(combobox.active)
        main_instance.update("scan_disc_finished")
      end
    end

  private

    def create_release_info_table
      rows = 7; columns = 2; homogeneous = false
      @release_info_table = Gtk::Table.new(rows, columns, homogeneous)

      title_label     = Gtk::Label.new(_("Title:"));       title_label.set_alignment(0.0, 0.5)
      date_label      = Gtk::Label.new(_("Date:"));        date_label.set_alignment(0.0, 0.5)
      desc_label      = Gtk::Label.new(_("Description:")); desc_label.set_alignment(0.0, 0.5)
      country_label   = Gtk::Label.new(_("Country:"));     country_label.set_alignment(0.0, 0.5)
      packaging_label = Gtk::Label.new(_("Packaging:"));   packaging_label.set_alignment(0.0, 0.5)
      status_label    = Gtk::Label.new(_("Status:"));      status_label.set_alignment(0.0, 0.5)
      barcode_label   = Gtk::Label.new(_("Barcode:"));     barcode_label.set_alignment(0.0, 0.5)

      @title_value     = Gtk::Label.new(_("Unknown title"));          title_value.set_alignment(0.0, 0.5)
      @date_value      = Gtk::Label.new(_("Unknown date"));           date_value.set_alignment(0.0, 0.5)
      @desc_value      = Gtk::Label.new(_("Unknown description"));    desc_value.set_alignment(0.0, 0.5)
      @country_value   = Gtk::Label.new(_("Unknown country code"));   country_value.set_alignment(0.0, 0.5)
      @packaging_value = Gtk::Label.new(_("Unknown packaging type")); packaging_value.set_alignment(0.0, 0.5)
      @status_value    = Gtk::Label.new(_("Unknown status"));         status_value.set_alignment(0.0, 0.5)
      @barcode_value   = Gtk::Label.new(_("Unknown barcode"));        barcode_value.set_alignment(0.0, 0.5)

      release_info_table.tap do |t|
        fill   = Gtk::AttachOptions::FILL
        shrink = Gtk::AttachOptions::SHRINK
        t.attach(title_label,     0, 1, 0, 1, fill, shrink,  0, 0)
        t.attach(title_value,     1, 2, 0, 1, fill, shrink, 10, 0)
        t.attach(date_label,      0, 1, 1, 2, fill, shrink,  0, 0)
        t.attach(date_value,      1, 2, 1, 2, fill, shrink, 10, 0)
        t.attach(desc_label,      0, 1, 2, 3, fill, shrink,  0, 0)
        t.attach(desc_value,      1, 2, 2, 3, fill, shrink, 10, 0)
        t.attach(country_label,   0, 1, 3, 4, fill, shrink,  0, 0)
        t.attach(country_value,   1, 2, 3, 4, fill, shrink, 10, 0)
        t.attach(packaging_label, 0, 1, 4, 5, fill, shrink,  0, 0)
        t.attach(packaging_value, 1, 2, 4, 5, fill, shrink, 10, 0)
        t.attach(status_label,    0, 1, 5, 6, fill, shrink,  0, 0)
        t.attach(status_value,    1, 2, 5, 6, fill, shrink, 10, 0)
        t.attach(barcode_label,   0, 1, 6, 7, fill, shrink,  0, 0)
        t.attach(barcode_value,   1, 2, 6, 7, fill, shrink, 10, 0)
      end
    end

    def update_release_info_table
      current_selection = combobox.active
      release = choices[current_selection]

      update_ui = ->(element_key, gtk_label, unset_text) do
        if release&.elements[element_key]&.text
          gtk_label.text = release.elements[element_key].text
        else
          gtk_label.text = unset_text
        end
      end

      update_ui.call("title",          title_value,     _("Unknown title"))
      update_ui.call("date",           date_value,      _("Unknown date"))
      update_ui.call("disambiguation", desc_value,      _("Unknown description"))
      update_ui.call("country",        country_value,   _("Unknown country code"))
      update_ui.call("packaging",      packaging_value, _("Unknown packaging type"))
      update_ui.call("status",         status_value,    _("Unknown status"))
      update_ui.call("barcode",        barcode_value,   _("Unknown barcode"))
    end
  end
end
end
