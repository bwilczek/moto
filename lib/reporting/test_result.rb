module Moto
  module Reporting

    # Value object representing information about single test run
    class TestResult

      PENDING  = :result_pending   # -2
      RUNNING  = :result_running   # -1
      PASSED   = :result_passed    # 0
      FAILURE  = :result_failure   # 1
      ERROR    = :result_error     # 2
      SKIPPED  = :result_skipped   # 3

      # Result of a single test run
      attr_accessor :result

      # Optional message that might accompany the result of a single test run
      attr_accessor :message

    end
  end
end
