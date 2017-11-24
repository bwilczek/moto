require_relative 'result'

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

      # Partially demodulized class name, used for display purposes
      attr_accessor :display_name

      # Array of [Moto::Test::Result], each item represents a result of a single attempt to pass the test
      attr_reader :results

      # Set of params on which test was based
      attr_accessor :params

      # Time of test's start
      attr_accessor :time_start

      # Time of test's finish
      attr_accessor :time_end

      # Test's duration
      attr_accessor :duration

      # TODO: Burn it with fire...
      # Path to test's log, for purpose of making test logs accessible via listeners
      attr_accessor :log_path

      # Amount of attempts that have been made to successfuly complete a test
      attr_accessor :attempts

      def initialize
        @results = []
        @attempts = 0
      end

      def initialize_run
        if @time_start.nil?
          @time_start = Time.now.to_f
        end

        @attempts += 1

        result = Moto::Test::Result.new
        result.code = Moto::Test::Result::RUNNING
        @results.push(result)
      end

      #
      def finalize_run
        last_result = @results.last

        if last_result.code == Moto::Test::Result::RUNNING
          last_result.code = Moto::Test::Result::PASSED
        end

        @time_end = Time.now.to_f
        @duration = time_end - time_start
      end

      # Evaluates result.code and message based on exceptions, dispatched by test during test attempt
      # @param [Exception] exception thrown during test run
      def log_exception(exception)
        current_result = @results.last

        if exception.nil? || exception.is_a?(Moto::Exceptions::TestForcedPassed)
          current_result.code = Moto::Test::Result::PASSED
          current_result.message = exception.message
        elsif exception.is_a?(Moto::Exceptions::TestSkipped)
          current_result.code = Moto::Test::Result::SKIPPED
          current_result.message = exception.message
        elsif exception.is_a?(Moto::Exceptions::TestForcedFailure)
         log_failure(exception.message)
        else
          current_result.code = Moto::Test::Result::ERROR
          current_result.message = exception.message
        end
      end

      # Logs a failure, from assertion or forced, to the list of failures
      # @param [String] message of a failure to be added to the list
      def log_failure(message)
        current_result = @results.last
        current_result.code = Moto::Test::Result::FAILURE
        current_result.failures.push(message)
      end


      # Overwritten definition of to string.
      # @return [String] string with readable form of @results.last.code
      def to_s
        case @results.last.code
          when Moto::Test::Result::PASSED   then return 'PASSED'
          when Moto::Test::Result::FAILURE  then return 'FAILED'
          when Moto::Test::Result::ERROR    then return 'ERROR'
          when Moto::Test::Result::SKIPPED  then return 'SKIPPED'
        end
      end

    end
  end
end
