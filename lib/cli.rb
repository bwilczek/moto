require 'logger'
require 'pp'
require 'yaml'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'

module MotoApp
  DIR = Dir.pwd
end

module Moto
  DIR = File.dirname(File.dirname(__FILE__))
end

require_relative './empty_listener'
require_relative './forward_context_methods'
require_relative './test_logging'
require_relative './runner_logging'
require_relative './runner'
require_relative './thread_context'
require_relative './thread_pool'
require_relative './result'
require_relative './assert'
require_relative './test'
require_relative './page'
require_relative './version'
require_relative './clients/base'
require_relative './listeners/base'
require_relative './listeners/console'
require_relative './listeners/console_dots'
require_relative './listeners/junit_xml'
require_relative './listeners/webui'
require_relative './test_generator'
require_relative './exceptions/moto'
require_relative './exceptions/test_skipped'
require_relative './exceptions/test_forced_failure'
require_relative './exceptions/test_forced_passed'

module Moto

  class Cli
    def self.run(argv)
      test_paths_absolute = []
      test_classes = []

      unless argv[ :tests ].nil?
        argv[ :tests ].each do |dir_name|
          test_paths = Dir.glob("#{MotoApp::DIR}/tests/#{dir_name}/**/*.rb")
          test_paths -= test_paths_absolute
          test_paths_absolute += test_paths
        end
      end

      # TODO Optimization for files without #MOTO_TAGS
      unless argv[:tags].nil?
        tests_total = Dir.glob("#{MotoApp::DIR}/tests/**/*.rb")
        tests_total.each do |test_path|
          test_body = File.read(test_path)
          matches = test_body.match(/^#(\s*)MOTO_TAGS:([^\n\r]+)$/m)
          if matches
            test_tags = matches.to_a[2].gsub(/\s*/, '').split(',')
            test_paths_absolute << test_path unless (argv[:tags]&test_tags).empty?
          end
        end
      end

      #TODO Display criteria used
      if test_paths_absolute.empty?
        puts 'No tests found for given arguments.'
        exit 1
      end

      # Requires custom initializer if provided by application that uses Moto
      if File.exists?( "#{MotoApp::DIR}/lib/initializer.rb" )
        require("#{Moto::DIR}/lib/initializer.rb")
        require("#{MotoApp::DIR}/lib/initializer.rb")
        initializer = MotoApp::Initializer.new(self)
        initializer.init
      end

      tg = TestGenerator.new(MotoApp::DIR)
      test_paths_absolute.each do |test_path|
        test_classes << tg.generate(test_path)
      end

      listeners = []
      argv[ :reporters ].each do |r|
        listener = 'Moto::Listeners::' + r.camelize
        listeners << listener.constantize
      end

      runner = Moto::Runner.new(test_classes, listeners, argv[:environments], argv[:config], argv[:name])
      runner.run
    end

  end
end
