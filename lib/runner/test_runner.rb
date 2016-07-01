require_relative '../reporting/test_reporter'
require_relative './test_provider'

module Moto
  module Runner
    class TestRunner

      attr_reader :test_reporter

      def initialize(test_paths_absolute, test_reporter, test_path_params)
        @test_paths_absolute = test_paths_absolute
        @test_reporter = test_reporter
        @test_path_params = test_path_params
      end

      def run
        test_provider = TestProvider.new(@test_paths_absolute, @test_path_params)
        threads_max = Moto::Lib::Config.moto[:test_runner][:thread_count] || 1

        # remove log/screenshot files from previous execution
        @test_paths_absolute.each do |test_path|
          FileUtils.rm_rf("#{File.dirname(test_path)}/logs")
        end

        @test_reporter.report_start_run

        # Create as many threads as we're allowed by the config file.
        # test_provider.get_test - will invoke Queue.pop thus putting the thread to sleep
        # once there is no more work.

        Thread.abort_on_exception = true

        (1..threads_max).each do |index|
          Thread.new do
            Thread.current[:id] = index
            loop do
              Thread.current['clients_manager'] = Moto::Lib::Clients::ClientsManager.new

              tc = ThreadContext.new(test_provider.get_test, @test_reporter)
              tc.run
            end
          end
        end

        # Waiting for all threads to run out of work so we can end the application
        loop do
          if test_provider.num_waiting == threads_max
            break
          end

          sleep 1
        end

        @test_reporter.report_end_run
      end

    end
  end
end