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
require_relative './runner/dry_runner'
require_relative './runner/test_runner'
require_relative './runner/thread_context'
require_relative './runner/test_generator'
require_relative './test/base'
require_relative './test/metadata'
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

      tests_metadata = []
      directories   = argv[:tests]
      tags          = argv[:tags]
      filters       = argv[:filters]

      if directories
        directories.each do |directory|
          Dir.glob("#{MotoApp::DIR}/tests/#{directory}/**/*.rb").each do |test_path|
            tests_metadata << Moto::Test::Metadata.new(test_path)
          end
        end
      end

      if tags
        tests_total = Dir.glob("#{MotoApp::DIR}/tests/**/*.rb")
        tests_total.each do |test_path|

          metadata = Moto::Test::Metadata.new(test_path)
          tests_metadata << metadata unless (tags & metadata.tags).empty?

        end
      end

      # Make sure there are no repetitions in gathered set
      tests_metadata.uniq! { |metadata| metadata.test_path }

      # Tests to be removed due to filtering will be gathered in this array
      # [].delete(item) cannot be used since it interferes with [].each
      unfit_metadata = []

      # Filter tests by provied tags
      # - test must contain ALL tags specified with -f param
      # - test may contain other tags
      if filters
        tests_metadata.each do |metadata|

          # If test has no tags at all and filters are set it should be automatically removed
          if metadata.tags.empty?
            unfit_metadata << metadata
          # Otherwise check provided tags and filters for compatibility
          elsif (metadata.tags & filters).length != filters.length
            unfit_metadata << metadata
          end

        end
      end

      tests_metadata -= unfit_metadata

      #TODO Display criteria used
      if tests_metadata.empty?
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

      run_params = {}
      run_params[:run_name]   = argv[:run_name]
      run_params[:suite_name] = argv[:suite_name]
      run_params[:assignee]   = argv[:assignee]

      test_reporter = Moto::Reporting::TestReporter.new(argv[:listeners], run_params)

      if Moto::Lib::Config.moto[:test_runner][:dry_run]
        runner = Moto::Runner::DryRunner.new(tests_metadata, test_reporter)
      else
        runner = Moto::Runner::TestRunner.new(tests_metadata, test_reporter, argv[:stop_on])
      end
      runner.run
    end

  end
end
