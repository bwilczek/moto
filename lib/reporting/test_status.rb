module Moto
  module Reporting
    class TestStatus

      # Name of the test
      attr_accessor :name

      # Class representing test
      attr_accessor :class

      # Array of results, consists of [Moto::Reporting::TestResult]
      # so each item holds information about result code and message that might accompany it
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

      def initialize
        @results = []
      end

      # @results[test.name] = { class: test.class, result: RUNNING, env: test.env, params: test.params, name: test.name, error: nil, failures: [], started_at: Time.now.to_f }

      # Evaluates the result after the test has been run (single attempt)
      # @param [Exception] attempt_exception An optional exception that might have been raised during the execution of the test
      def evaluate_status_after_run(attempt_exception = nil)
        @time_end = Time.now.to_f
        @duration = @time_end - @time_start

        new_result = Moto::Reporting::TestResult.new

        # Convert exception, or its absence, into a result code that we can store
        if attempt_exception.nil?
          new_result.result = Moto::Reporting::TestResult::PASSED
        elsif attempt_exception.is_a? Moto::Exceptions::TestSkipped
          new_result.result = Moto::Reporting::TestResult::SKIPPED
        elsif attempt_exception.is_a? Moto::Exceptions::TestForcedPassed
          new_result.result = Moto::Reporting::TestResult::PASSED
        elsif attempt_exception.is_a? Moto::Exceptions::TestForcedFailure
          new_result.result = Moto::Reporting::TestResult::FAILURE
        else
          new_result.result = Moto::Reporting::TestResult::ERROR
        end

        # If there was an exception attach its message to the result object
        if !attempt_exception.nil?
          new_result.message = attempt_exception.message
        end

        @results.push(new_result)

        # TODO: Figure out where to use data from this array and evaluate "final result" of the test

      end
    end
  end
end
