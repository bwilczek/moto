module Moto
  module Reporting

    # Value object holding information about whole 'run' of tests.
    class RunStatus

      PASSED   = :passed    # 0
      FAILURE  = :failure   # 1
      ERROR    = :error     # 2
      SKIPPED  = :skipped   # 3

      # Array of all statuses [Moto::Test:Status] from current run
      attr_reader :tests_all

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::PASSED]
      attr_reader :tests_passed

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::SKIPPED]
      attr_reader :tests_skipped

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::FAILURE]
      attr_reader :tests_failed

      # Array of [Moto::Test:Status] with final_result == [Moto::Test::Result::ERROR]
      attr_reader :tests_error

      def initialize
        @tests_all      = []
        @tests_passed   = []
        @tests_skipped  = []
        @tests_failed   = []
        @tests_error    = []
        @duration       = 0
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

      # Time of run's start. Available after the first test has been completed.
      # @return [Float] Returns time of run's start (start of first test in it)
      def time_start
        if tests_all.empty?
          raise 'Moto::Reporting::RunStatus.time_start: Value not available. Check method description.'
        end

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

      # Adds single test's status to the collection which describes whole run
      # @param [Moto::Test::Status] test_status to be incorporated into final run result
      def add_test_status(test_status)

        # Separate collections are kept and data is doubled in order to avoid
        # calling Array.collect in getter for each type of results

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

        @tests_all << test_status
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
