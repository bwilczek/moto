module Moto
  module Reporting

    # Value object holding information about whole 'run' of tests.
    class RunStatus

      # Number of tests passed in current run
      attr_accessor :tests_passed

      # Number of tests skipped in current run
      attr_accessor :tests_skipped

      # Number of tests failed in current run
      attr_accessor :tests_failed

      # Number of tests with errors in current run
      attr_accessor :tests_errors

    end
  end
end
