module Moto
  module Reporting

    # Value object holding information about whole 'run' of tests.
    class RunStatus

      # Array of all statuses [Moto::Test:Status] from current run
      attr_reader :tests_all

      # Array of [Moto::Test:Status] with @results.last.code == [Moto::Test::Result::PASSED]
      attr_reader :tests_passed

      # Array of [Moto::Test:Status] with @results.last.code == [Moto::Test::Result::SKIPPED]
      attr_reader :tests_skipped

      # Array of [Moto::Test:Status] with @results.last.code == [Moto::Test::Result::FAILURE]
      attr_reader :tests_failed

      # Array of [Moto::Test:Status] with @results.last.code == [Moto::Test::Result::ERROR]
      attr_reader :tests_error

      # Time of run's start
      attr_reader :time_start

      # Time of run's end
      attr_reader :time_end

      # Run's duration
      attr_reader :duration

      def initialize
        @tests_all      = []
        @tests_passed   = []
        @tests_skipped  = []
        @tests_failed   = []
        @tests_error    = []
      end

      def initialize_run
        @time_start = Time.now.to_f
      end

      def finalize_run
        @time_end = Time.now.to_f
        @duration = @time_end - @time_start
      end

      # Summarized result of whole run
      # @return [String] one of the values defined as constants in this class in cohesion with [Moto::Test::Result]
      def result

        if @tests_error.length > 0
          return Moto::Test::Result::ERROR
        elsif @tests_failed.length > 0
          return Moto::Test::Result::FAILURE
        elsif tests_all.length == @tests_skipped.length
          return Moto::Test::Result::SKIPPED
        end

        Moto::Test::Result::PASSED
      end

      # Adds single test's status to the collection which describes whole run
      # @param [Moto::Test::Status] test_status to be incorporated into final run result
      def add_test_status(test_status)

        # Separate collections are kept and data is doubled in order to avoid
        # calling Array.collect in getter for each type of results

        case test_status.results.last.code
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
          when Moto::Test::Result::PASSED   then return 'PASSED'
          when Moto::Test::Result::FAILURE  then return 'FAILED'
          when Moto::Test::Result::ERROR    then return 'ERROR'
          when Moto::Test::Result::SKIPPED  then return 'SKIPPED'
        end
      end


      # Inform about presence o errors/failures/skipped tests in current test run as a bitmap
      # errors present: 0b100 & status_as_bitmap
      # fails present:  0b010 & status_as_bitmap
      # skips present:  0b001 & status_as_bitmap
      # all passed:     status_as_bitmap == 0
      def bitmap
        status = 0

        if tests_error.length > 0
          status += 0b100
        end

        if tests_failed.length > 0
          status += 0b010
        end

        if tests_skipped.length > 0
          status += 0b001
        end

        status
      end

    end
  end
end
