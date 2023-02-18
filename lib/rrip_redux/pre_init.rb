# Copyright 2022-2023 Dan Higgins (https://github.com/lilole)
# Copyright 2007-2013 Bouke Woudstra (boukewoudstra@gmail.com)
# If you use this file then you must apply the LICENSE file at the root of this project.

require "thread"

module RripRedux
  VERSION = "0.9.0"

  $app_version = VERSION
  $app_url     = "https://github.com/lilole/rrip_redux"

  module PreInit
    def self.run
      # Crash on errors, because bugs are otherwise hard to find
      Thread.abort_on_exception = true

      assert_ruby_version
      check_gettext
    end

    def self.assert_ruby_version
      major_version = RUBY_VERSION.delete(".")[0..1].to_i
      if major_version < 27
        puts "Ruby versions older than 2.7 are not supported."
        puts "Please upgrade Ruby to a recent version."
        exit(1)
      end
    end

    # Make sure the basic API to the locale files works.
    #
    def self.check_gettext
      err1 = gettext_require_error
      err2 = ! err1 && gettext_method_error
      return true unless err1 || err2

      fake_gettext
      err3 = gettext_method_error
      if err3
        puts "Cannot configure GetText. Aborting."
        raise err3
      elsif err2
        puts err2.exception
        puts err2.backtrace
        puts "ruby-gettext is crashing. Translations are disabled."
      elsif err1
        puts "ruby-gettext is not found. Translations are disabled."
      end
      false
    end

    def self.gettext_require_error
      require "gettext"
      nil
    rescue LoadError => e
      return e
    end

    def self.gettext_method_error
      ENV["GETTEXT_PATH"] ||= File.expand_path("../../../locale", __FILE__)

      Class.new do
        ::GetText.bindtextdomain("rrip_redux")
        include ::GetText
        _("test")
      end
      nil
    rescue Exception => e
      ENV.delete("GETTEXT_PATH")
      return e
    end

    def self.fake_gettext
      Object.const_set(:GetText, FakeGetText)
    end

    module FakeGetText
      def self.included(includer)
        includer.extend ClassAndInstanceMethods
      end

      module ClassAndInstanceMethods
        def bindtextdomain(domain) nil end
        def _(txt) txt end
      end

      extend  ClassAndInstanceMethods
      include ClassAndInstanceMethods
    end
  end
end
