module Moto
  module Test

    # Value object representing information about single test run
    class Result

      PASSED   = :result_passed    # 0
      FAILURE  = :result_failure   # 1
      ERROR    = :result_error     # 2
      SKIPPED  = :result_skipped   # 3

      # Result code of a single test run
      attr_accessor :code

      # Optional message that might accompany the result of a single test run
      attr_accessor :message

    end
  end
end
