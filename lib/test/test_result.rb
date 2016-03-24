module Moto
  module Test

    # Value object representing information about single test run
    class Result

      PASSED   = :passed    # 0
      FAILURE  = :failure   # 1
      ERROR    = :error     # 2
      SKIPPED  = :skipped   # 3

      # Result code of a single test run
      attr_accessor :code

      # Optional message that might accompany the result of a single test run
      attr_accessor :message

    end
  end
end
