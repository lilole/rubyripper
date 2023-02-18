# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# You must apply the LICENSE file at the root of this project to this file.

require 'rexml/document'

module RripRedux
module Gtk3
  # MultipleMusicBraizHits handles the window while displaying the dialog
  # when multiple musicbrainz hits are offered to the user.
  # Notice that the left part of the gui with the icons is not in this class.
  #
  class MultipleMusicBrainzHits
    include GetText; GetText.bindtextdomain("rrip_redux")

    attr_reader :display

    def initialize(metadata, main_instance)
      @label1 = Gtk::Label.new(_("The musicbrainz server reports multiple releases.\nWhich one would you prefer?"))
      @image1 = Gtk::Image.new(:stock => Gtk::Stock::DIALOG_QUESTION, :size => Gtk::IconSize::DIALOG)
      @hbox1 = Gtk::Box.new(:horizontal)
      [@image1, @label1].each{|object| @hbox1.pack_start(object)}

      @choices = metadata.getChoices()
      @combobox = Gtk::ComboBoxText.new()
      metadata.getChoices().each{|release| @combobox.append_text(release.attribute('id').to_s)}
      createReleaseInfoTable()
      @combobox.signal_connect("changed") do
        updateReleaseInfoTable()
      end
      @combobox.active = 0
      @vbox2 = Gtk::Box.new(:vertical)
      [@combobox, @releaseInfoTable].each{|object| @vbox2.pack_start(object, :expand => true, :fill => true, :padding => 5)}

      @separator1 = Gtk::Separator.new(:horizontal)

      @button1 = Gtk::Button.new
      @label2 = Gtk::Label.new(_("Ok"))
      @image2 = Gtk::Image.new(:stock => Gtk::Stock::OK, :size => Gtk::IconSize::LARGE_TOOLBAR)
      @hbox3 = Gtk::Box.new(:horizontal)
      [@image2, @label2].each{|object| @hbox3.pack_start(object, :expand => false, :fill => false, :padding => 10)}
      @button1.add(@hbox3)
      @hbox4 = Gtk::Box.new(:horizontal)
      @hbox4.pack_start(@button1, :expand => true, :fill => false)

      @vbox1 = Gtk::Box.new(:vertical)
      @vbox1.border_width = 10
      [@hbox1, @vbox2, @separator1, @hbox4].each{|object| @vbox1.pack_start(object, :expand => false, :fill => false, :padding => 10)}

      @display = Gtk::Frame.new(_("Multiple releases found...")) # will contain the above
      @display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
      @display.border_width = 5
      @display.add(@vbox1)
      @button1.signal_connect("released") do
        metadata.choose(@combobox.active)
        main_instance.update('scan_disc_finished')
      end
    end

    private

    def createReleaseInfoTable()
      @releaseInfoTable = Gtk::Table.new(rows=7, columns=2, homogeneous=false)
      title_label = Gtk::Label.new(_("Title:")) ; title_label.set_alignment(0.0, 0.5)
      date_label = Gtk::Label.new(_("Date:")) ; date_label.set_alignment(0.0, 0.5)
      desc_label = Gtk::Label.new(_("Description:")) ; desc_label.set_alignment(0.0, 0.5)
      country_label = Gtk::Label.new(_("Country:")) ; country_label.set_alignment(0.0, 0.5)
      packaging_label = Gtk::Label.new(_("Packaging:")) ; packaging_label.set_alignment(0.0, 0.5)
      status_label = Gtk::Label.new(_("Status:")) ; status_label.set_alignment(0.0, 0.5)
      barcode_label = Gtk::Label.new(_("Barcode:")) ; barcode_label.set_alignment(0.0, 0.5)

      @title_value = Gtk::Label.new(_("Unknown title")) ; @title_value.set_alignment(0.0, 0.5)
      @date_value = Gtk::Label.new(_("Unknown date")) ; @date_value.set_alignment(0.0, 0.5)
      @desc_value = Gtk::Label.new(_("Unknown description")) ; @desc_value.set_alignment(0.0, 0.5)
      @country_value = Gtk::Label.new(_("Unknown country code")) ; @country_value.set_alignment(0.0, 0.5)
      @packaging_value = Gtk::Label.new(_("Unknown packaging type")) ; @packaging_value.set_alignment(0.0, 0.5)
      @status_value = Gtk::Label.new(_("Unknown status")) ; @status_value.set_alignment(0.0, 0.5)
      @barcode_value = Gtk::Label.new(_("Unknown barcode")) ; @barcode_value.set_alignment(0.0, 0.5)

      @releaseInfoTable.attach(title_label, 0, 1, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@title_value, 1, 2, 0, 1, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
      @releaseInfoTable.attach(date_label, 0, 1, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@date_value, 1, 2, 1, 2, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
      @releaseInfoTable.attach(desc_label, 0, 1, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@desc_value, 1, 2, 2, 3, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
      @releaseInfoTable.attach(country_label, 0, 1, 3, 4, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@country_value, 1, 2, 3, 4, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
      @releaseInfoTable.attach(packaging_label, 0, 1, 4, 5, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@packaging_value, 1, 2, 4, 5, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
      @releaseInfoTable.attach(status_label, 0, 1, 5, 6, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@status_value, 1, 2, 5, 6, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
      @releaseInfoTable.attach(barcode_label, 0, 1, 6, 7, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 0, 0)
      @releaseInfoTable.attach(@barcode_value, 1, 2, 6, 7, Gtk::AttachOptions::FILL, Gtk::AttachOptions::SHRINK, 10, 0)
    end

    def updateReleaseInfoTable()
      currentSelection = @combobox.active
      release = @choices[currentSelection]

      if release.elements["title"] and release.elements["title"].text
        @title_value.text = release.elements["title"].text
      else
        @title_value.text = _("Unknown title")
      end

      if release.elements["date"] and release.elements["date"].text
        @date_value.text = release.elements["date"].text
      else
        @date_value.text = _("Unknown date")
      end

      if release.elements["disambiguation"] and release.elements["disambiguation"].text
        @desc_value.text = release.elements["disambiguation"].text
      else
        @desc_value.text = _("Unknown description")
      end

      if release.elements["country"] and release.elements["country"].text
        @country_value.text = release.elements["country"].text
      else
        @country_value.text = _("Unknown country code")
      end

      if release.elements["packaging"] and release.elements["packaging"].text
        @packaging_value.text = release.elements["packaging"].text
      else
        @packaging_value.text = _("Unknown packaging type")
      end

      if release.elements["status"] and release.elements["status"].text
        @status_value.text = release.elements["status"].text
      else
        @status_value.text = _("Unknown status")
      end

      if release.elements["barcode"] and release.elements["barcode"].text
        @barcode_value.text = release.elements["barcode"].text
      else
        @barcode_value.text = _("Unknown barcode")
      end
    end
  end
end
end
