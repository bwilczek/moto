require_relative '../../reporting/test_reporter'
require_relative '../../test/generator'

module Moto
  module Modes
    module Run
      class DryRunner

        # @param [Array] tests_metadata Collection of [Moto::Test::Metadata] objects describing Tests
        # @param [Moto::Reporting::TestReporter] test_reporter Reporter of test/run statuses that communicates with external status listeners
        def initialize(tests_metadata, test_reporter)
          @tests_metadata = tests_metadata
          @test_reporter = test_reporter
        end

        def run
          @test_reporter.report_start_run

          test_generator = Moto::Test::Generator.new
          @tests_metadata.each do |metadata|
            test_variants = test_generator.get_test_with_variants(metadata)
            test_variants.each do |tc|
              @test_reporter.report_start_test(tc.status, tc.metadata)
              tc.status.initialize_run
              tc.status.log_exception(Exceptions::TestSkipped.new('Dry run.'))
              tc.status.finalize_run
              @test_reporter.report_end_test(tc.status)
            end
          end

          @test_reporter.report_end_run

          # Exit application with code that represents status of test run
          Kernel.exit(@test_reporter.run_status.bitmap)
        end

      end
    end
  end
end