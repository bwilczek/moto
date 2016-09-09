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

require_relative './test_logging'
require_relative './runner_logging'
require_relative './runner/test_runner'
require_relative './runner/thread_context'
require_relative './runner/test_generator'
require_relative './test/base'
require_relative './version'
require_relative './reporting/listeners/base'
require_relative './reporting/listeners/console'
require_relative './reporting/listeners/console_dots'
require_relative './reporting/listeners/junit_xml'
require_relative './reporting/listeners/webui'
require_relative './exceptions/moto'
require_relative './exceptions/test_skipped'
require_relative './exceptions/test_forced_failure'
require_relative './exceptions/test_forced_passed'
require_relative 'config'

module Moto

  class Cli
    def self.run(argv)

      test_paths_absolute = []
      directories   = argv[:tests]
      tags          = argv[:tags]
      filters       = argv[:filters]

      if directories
        directories.each do |directory|
          test_paths_absolute += Dir.glob("#{MotoApp::DIR}/tests/#{directory}/**/*.rb")
        end
      end

      if tags
        tests_total = Dir.glob("#{MotoApp::DIR}/tests/**/*.rb")
        tests_total.each do |test_path|

          test_body = File.read(test_path)
          matches = test_body.match(/^#(\s*)MOTO_TAGS:(.*?)$/)

          if matches
            test_tags = matches.to_a[2].gsub(/\s*/, '').split(',')
            test_paths_absolute << test_path unless (tags & test_tags).empty?
          end

        end
      end

      # Make sure there are no repetitions in gathered set
      test_paths_absolute.uniq!

      # Tests to be removed due to filtering will be gathered in this array
      # [].delete(item) cannot be used since it interferes with [].each
      filtered_test_paths = []

      # Filter tests by provied tags
      if filters
        test_paths_absolute.each do |test_path|
          test_body = File.read(test_path)

          matches = test_body.match(/^#(\s*)MOTO_TAGS:(.*?)$/)

          if matches

            test_tags = matches.to_a[2].gsub(/\s*/, '').split(',')
            if (filters & test_tags).empty?
              # Test doesn't contain any tags to be filtered upon
              filtered_test_paths << test_path
            end

          else
            # Test has no tags at all
            filtered_test_paths << test_path
          end

        end
      end

      test_paths_absolute -= filtered_test_paths

      #TODO Display criteria used
      if test_paths_absolute.empty?
        puts 'No tests found for given arguments.'
        Kernel.exit(-1)
      end

      # Requires custom initializer if provided by application that uses Moto
      if File.exists?( "#{MotoApp::DIR}/lib/initializer.rb" )
        require("#{Moto::DIR}/lib/initializer.rb")
        require("#{MotoApp::DIR}/lib/initializer.rb")
        initializer = MotoApp::Lib::Initializer.new(self)
        initializer.init
      end

      test_reporter = Moto::Reporting::TestReporter.new(argv[:listeners], argv[:name])

      runner = Moto::Runner::TestRunner.new(test_paths_absolute, test_reporter)
      runner.run
    end

  end
end
