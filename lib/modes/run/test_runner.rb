require_relative '../../reporting/test_reporter'
require_relative 'test_provider'
require_relative 'thread_context'

module Moto
  module Modes
    module Run
      class TestRunner

        attr_reader :test_reporter

        # @param [Array] tests_metadata Collection of [Moto::Test::Metadata] objects describing Tests
        # @param [Moto::Reporting::TestReporter] test_reporter Reporter of test/run statuses that communicates with external status listeners
        # @param [Hash] stop_conditions Describe when TestRunner should abnormally stop its execution
        #   :error  [Boolean]
        #   :fail   [Boolean]
        #   :skip   [Boolean]
        def initialize(tests_metadata, test_reporter, stop_conditions)
          @tests_metadata = tests_metadata
          @test_reporter = test_reporter
          @stop_conditions = stop_conditions
        end

        def run
          test_provider = TestProvider.new(@tests_metadata)
          threads_max = Moto::Config::Manager.config_moto[:test_runner][:thread_count] || 1

          # remove log/screenshot files from previous execution
          @tests_metadata.each do |metadata|
            FileUtils.rm_rf("#{File.dirname(metadata.test_path)}/logs")
          end

          @test_reporter.report_start_run

          # Create as many threads as we're allowed by the config file.
          # test_provider.get_test - will invoke Queue.pop thus putting the thread to sleep
          # once there is no more work.

          Thread.abort_on_exception = true

          threads_max.times do
            Thread.new do

              loop do
                tc = ThreadContext.new(test_provider.get_test, @test_reporter)
                tc.run

                # unset all leftover variables stored 'globally' in Thread
                Thread.current.keys.each do |k|
                  Thread.current[k] = nil
                end

              end
            end
          end

          # Waiting for all threads to run out of work so we can end the application
          # or abnormal termination to be triggered based on options provided by the user
          loop do
            run_status = @test_reporter.run_status
            if (test_provider.num_waiting == threads_max) ||
                (@stop_conditions[:error] && run_status.tests_error.length > 0) ||
                (@stop_conditions[:fail] && run_status.tests_failed.length > 0) ||
                (@stop_conditions[:skip] && run_status.tests_skipped.length > 0)
              break
            end

            sleep 2
          end

          @test_reporter.report_end_run

          # Exit application with code that represents status of test run
          Kernel.exit(@test_reporter.run_status.bitmap)
        end

      end
    end
  end
end