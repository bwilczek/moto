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

              # Validate if tags are not empty
              if @validation_options[:has_tags] && metadata.tags.empty?
                test.status.log_exception(Exceptions::TestForcedFailure.new('No tags.'))
              end

              # Validate if test description was provided
              if @validation_options[:has_description] && metadata.description.empty?
                test.status.log_exception(Exceptions::TestForcedFailure.new('No description.'))
              end

              # Validate if tags contain entries only from the whitelist
              if @validation_options.key?(:tag_whitelist)
                metadata.tags.each do |tag|
                  if !@validation_options[:tag_whitelist].include?(tag)
                    test.status.log_exception(Exceptions::TestForcedFailure.new("Tags contain non-whitelisted entry: #{tag}"))
                    break
                  end
                end
              end

              # Validate if provided regex is found within tags
              if @validation_options.key?(:tags_regex_positive)
                tags_string = metadata.tags.join(',')
                regexp = Regexp.new(@validation_options[:tags_regex_positive])
                result = regexp.match(tags_string)
                if result.nil?
                  test.status.log_exception(Exceptions::TestForcedFailure.new("Positive match should have been found in: #{metadata.tags.join(',')}"))
                end
              end

              # Validate if provided regex is NOT found within tags
              if @validation_options.key?(:tags_regex_negative)
                tags_string = metadata.tags.join(',')
                regexp = Regexp.new(@validation_options[:tags_regex_negative])
                result = regexp.match(tags_string)
                if !result.nil?
                  test.status.log_exception(Exceptions::TestForcedFailure.new("Negative match shouldn't have been found in: #{metadata.tags.join(',')}"))
                end
              end

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