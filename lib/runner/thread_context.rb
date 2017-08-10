require 'erb'
require 'fileutils'
require_relative '../../lib/config'

module Moto
  module Runner
    class ThreadContext

      attr_reader :test

      def initialize(test, test_reporter)
        @test = test
        @test_reporter = test_reporter

        log_directory = File.dirname(@test.log_path)
        if !File.directory?(log_directory)
          FileUtils.mkdir_p(log_directory)
        end

        file = File.open(@test.log_path, File::WRONLY | File::TRUNC | File::CREAT)
        file.chmod(0o666)
        Thread.current['logger'] = Logger.new(file)
        Thread.current['logger'].level = config[:test_log_level] || Logger::DEBUG
      end

      def run
        max_attempts = config[:test_attempt_max]   || 1
        sleep_time   = config[:test_attempt_sleep] || 0

        # Reporting: start_test
        @test_reporter.report_start_test(@test.status, @test.metadata)

        (1..max_attempts).each do |attempt|

          @test.before
          Thread.current['logger'].info("Start: #{@test.name} attempt #{attempt}/#{max_attempts}")

          begin
            @test.run_test
          rescue Exceptions::TestForcedPassed, Exceptions::TestForcedFailure, Exceptions::TestSkipped => e
            Thread.current['logger'].info(e.message)
          rescue Exception => e
            Thread.current['logger'].error("#{e.class.name}: #{e.message}")
            Thread.current['logger'].error(e.backtrace.join("\n"))
          end

          @test.after

          Thread.current['logger'].info("Result: #{@test.status.results.last.code}")

          # test should have another attempt in case of an error / failure / none at all
          unless (@test.status.results.last.code == Moto::Test::Result::ERROR   && config[:test_reattempt_on_error]) ||
                 (@test.status.results.last.code == Moto::Test::Result::FAILURE && config[:test_reattempt_on_fail] )
            break
          end

          # don't go to sleep in the last attempt
          if attempt < max_attempts
            sleep sleep_time
          end

        end # Make another attempt

        # Close and flush stream to file
        Thread.current['logger'].close

        # Reporting: end_test
        @test_reporter.report_end_test(@test.status)
      end

      # @return [Hash] Hash with config for ThreadContext
      def config
        Moto::Lib::Config.moto[:test_runner]
      end
      private :config

    end
  end
end
