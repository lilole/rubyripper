#!/usr/bin/env ruby
#
# rrip_redux - A secure ripper for Linux, based on Rubyripper.
#
# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2010 Bouke Woudstra (boukewoudstra@gmail.com)
#
# You must read the LICENSE file at the root of this project.

module RripRedux
  VERSION = "0.9.0"

  $app_version = VERSION
  $app_url     = "https://github.com/lilole/rrip_redux"

  module Base
    def self.init
      # Crash on errors, because bugs are otherwise hard to find
      Thread.abort_on_exception = true

      assert_ruby_version
      fake_gettext if ! check_gettext
    end

    def self.assert_ruby_version
      major_version = RUBY_VERSION.delete(".")[0..1].to_i
      if major_version < 27
        puts "Ruby versions older than 2.7 are not supported."
        puts "Please upgrade Ruby to a recent version."
        exit(1)
      end
    end

    def self.check_gettext
      # Make sure the locale files work before installing
      ENV["GETTEXT_PATH"] ||= File.expand_path("../../../locale", __FILE__)

      begin
        require "gettext"

        testGetTextClass = Class.new do
          ::GetText.bindtextdomain("rrip_redux")
          include ::GetText
          _("test")
        end
      rescue Exception => error
        if error.class == LoadError
          puts "ruby-gettext is not found. Translations are disabled."
        elsif error.class == NoMethodError
          puts error.exception()
          puts error.backtrace()
          puts "ruby-gettext is crashing. Translations are disabled."
        else
          raise error
        end
        return false
      end

      true
    end

    def self.fake_gettext
      module ::GetText
        def _(txt) txt end
        def self._(txt) txt end
        def self.bindtextdomain(domain) nil end
      end
    end
  end
end
