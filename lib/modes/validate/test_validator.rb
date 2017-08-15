require_relative '../../reporting/test_reporter'
require_relative '../../exceptions/test_skipped'
require_relative '../../exceptions/test_forced_failure'
require_relative '../../exceptions/test_forced_passed'
require_relative '../../test/generator'

module Moto
  module Modes
    module Validate
      class TestValidator

        # @param [Array] tests_metadata Collection of [Moto::Test::Metadata] objects describing Tests
        # @param [Hash] validation_options User input in form of a Hash - specifies options of validation
        # @param [Moto::Reporting::TestReporter] test_reporter Reporter of test/run statuses that communicates with external status listeners
        def initialize(tests_metadata, validation_options, test_reporter)

          @tests_metadata = tests_metadata
          @validation_options = validation_options
          @test_reporter = test_reporter
        end

        def run
          @test_reporter.report_start_run

          test_generator = Moto::Test::Generator.new

          @tests_metadata.each do |metadata|
            tests = test_generator.get_test_with_variants(metadata, 1)
            tests.each do |test|
              @test_reporter.report_start_test(test.status, test.metadata)
              test.status.initialize_run

              # TODO: Validate tags here

              if @validation_options[:has_tags] && metadata.tags.empty?
                test.status.log_exception(Exceptions::TestForcedFailure.new('No tags.'))
              end

              if @validation_options[:has_description] && metadata.description.empty?
                test.status.log_exception(Exceptions::TestForcedFailure.new('No description.'))
              end

              if @validation_options.key?(:tags_regex)
                #TODO: Discuss with Maciek the format of regex and how to join array - on ',' ?
              end

              # test.status.log_exception(Exceptions::TestSkipped.new('Dry run.'))
              test.status.finalize_run
              @test_reporter.report_end_test(test.status)
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