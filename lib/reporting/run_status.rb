module Moto
  module Reporting

    # Value object holding information about whole 'run' of tests.
    class RunStatus

      PASSED   = :result_passed    # 0
      FAILURE  = :result_failure   # 1
      ERROR    = :result_error     # 2
      SKIPPED  = :result_skipped   # 3

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::PASSED]
      attr_reader :tests_passed

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::SKIPPED]
      attr_reader :tests_skipped

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::FAILURE]
      attr_reader :tests_failed

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::ERROR]
      attr_reader :tests_error

      def initialize
        @tests_all      = nil
        @tests_passed   = []
        @tests_skipped  = []
        @tests_failed   = []
        @tests_error    = []
        @duration       = 0
      end

      # All [Moto::Test::Status], associated with the run, sorted by their time_start field
      # @param [Boolean] force_evaluation Optional, use when something might have changed between invocations of this method
      # @return [Array] array of all [Moto::Test:Status] sorted by time_start field
      def tests_all(force_evaluation = false)

        if @tests_all.nil? || force_evaluation
          @tests_all = tests_passed + tests_skipped + tests_failed + tests_error
          @tests_all = @tests_all.sort_by { |test_status| test_status.time_start }
        end

        @tests_all
      end

      # Sum of durations of all tests in this run
      # @param [Boolean] force_evaluation Optional, use when something might have changed between invocations of this method
      # @return [Float] summed up duration of whole run
      def duration(force_evaluation = false)

        if @duration == 0 || force_evaluation
          tests_all.each do |test_status|
            @duration += test_status.duration
          end
        end

        @duration
      end

      # @return [Float] Returns time of run's start (start of first test in it)
      def time_start
        tests_all[0].time_start
      end

      # Result of whole run, takes into account final_result field of all tests in this set
      # @return [String] one of the values defined as constants in this class in cohesion with [Moto::Test::Result]
      def result

        if @tests_error.length > 0
          return ERROR
        elsif @tests_failed.length > 0
          return FAILURE
        elsif tests_all.length == @tests_skipped.length
          return SKIPPED
        end

        PASSED
      end

      # Add single test's status to the collection which describes whole run
      # @param [Moto::Test::Status] test_status to be incorporated into final run result
      def add_test_status(test_status)
        case test_status.final_result.code
          when Moto::Test::Result::PASSED
            @tests_passed << test_status
          when Moto::Test::Result::SKIPPED
            @tests_skipped << test_status
          when Moto::Test::Result::FAILURE
            @tests_failed << test_status
          when Moto::Test::Result::ERROR
            @tests_error << test_status
          else
            raise 'Incorrect value of field: "code" in [Moto::Test::Status]'
        end
      end

      # Overwritten definition of to string.
      # @return [String] string with readable form of result field
      def to_s
        case result
          when PASSED   then return 'PASSED'
          when FAILURE  then return 'FAILED'
          when ERROR    then return 'ERROR'
          when SKIPPED  then return 'SKIPPED'
        end
      end
    end
  end
end
