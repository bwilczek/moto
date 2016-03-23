require_relative 'test_result'

module Moto
  module Test

    # Representation of single test's run status - it's passes, failures etc.
    # Pretty much a value object which's purpose is to be passed as a data provider for listeners.
    # Only methods here are just meant for data preparation. No communication with any external classes.
    class Status

      # Name of the test
      attr_accessor :name

      # Name of the class representing test
      attr_accessor :test_class_name

      # Array of results, consists of [Moto::Reporting::TestResult]
      # so each item holds information about result code and message that might accompany it.
      # *IMPORTANT* To access 'summarized' result refer to method: final_result
      attr_reader :results

      # Environment on which test was run
      attr_accessor :env

      # Set of params on which test was based
      attr_accessor :params

      # Time of test's start
      attr_accessor :time_start

      # Time of test's finish
      attr_accessor :time_end

      # Test's duration
      attr_accessor :duration

      # Indicates whether test is currently being executed or not
      # if :is_running == true and :final_result != nil it means that test has executed at least once
      attr_accessor :is_running

      # TODO: Burn it with fire...
      # Path to test's log, for purpose of making test logs accessible via listeners
      attr_accessor :log_path

      def initialize
        @is_running = false
        @results = []
      end

      # Utility function which helps in converting errors, dispatched by Moto during test run, to [Moto::Test::Result]
      # @param [Exception] exception thrown during test run or nil if test passed properly
      def exception_to_test_result(exception)
        new_result = Moto::Test::Result.new

        if exception.nil? || exception.is_a?(Moto::Exceptions::TestForcedPassed)
          new_result.code = Moto::Test::Result::PASSED
        elsif exception.is_a?(Moto::Exceptions::TestSkipped)
          new_result.code = Moto::Test::Result::SKIPPED
        elsif exception.is_a?(Moto::Exceptions::TestForcedFailure)
          new_result.code = Moto::Test::Result::FAILURE
        else
          new_result.code = Moto::Test::Result::ERROR
        end

        # If there was an exception attach its message to the result object
        if !exception.nil?
          new_result.message = exception.message
        end

        new_result
      end

      # Evaluates the result after the test has been run (single attempt)
      # @param [Exception] exception An optional exception that might have been raised during the execution of the test
      def evaluate_status_after_run(exception = nil)
        @time_end = Time.now.to_f
        @duration = time_end - time_start

        @results.push(exception_to_test_result(exception))
      end

      # Analyzes :results collection and decides which one should be used as a final summary of all test runs
      # Will return first encountered ERROR or, if no [Moto::Test::Result::ERROR] have been spotted, last result in the array
      # @return [Moto::Test::Result]
      def final_result
        temp_result = nil

        @results.each do |result|
          temp_result = result

          if result.code == Moto::Test::Result::ERROR
            break
          end
        end

        temp_result
      end

      # Overwritten definition of to string.
      # @return [String] string with readable form of final_result field
      def to_s
        case final_result.code
          when Moto::Test::Result::PASSED   then return 'PASSED'
          when Moto::Test::Result::FAILURE  then return 'FAILED'
          when Moto::Test::Result::ERROR    then return 'ERROR'
          when Moto::Test::Result::SKIPPED  then return 'SKIPPED'
        end
      end

    end
  end
end
