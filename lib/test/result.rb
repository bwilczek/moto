module Moto
  module Test

    # Value object representing information about results of a single attempt to pass the test
    class Result

      RUNNING  = :running   # -1
      PASSED   = :passed    # 0
      FAILURE  = :failure   # 1
      ERROR    = :error     # 2
      SKIPPED  = :skipped   # 3

      # Result code of a single test run
      attr_accessor :code

      # Optional message that might accompany the result of a single test run
      attr_accessor :message

      # An Array of Strings representing messages that accompany assertion and forced failures
      attr_accessor :failures

      def initialize
        @failures = []
      end

    end
  end
end
