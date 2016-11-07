module Moto
  module Reporting
    module Listeners

      # Base class for listeners that report results of testing 'outside' of the application.
      class Base

        attr_reader :run_params

        # @param [String] run_params Described in detail in [Moto::Reporting::TestReporter]
        def initialize(run_params)
          @run_params = run_params
        end

        # Invoked when whole batch of tests starts
        def start_run
          # Abstract
        end

        # Abstract
        # Invoked when whole batch of tests ends
        def end_run(run_status)
          # Abstract
        end

        # Abstract
        # Invoked when a single test is started
        def start_test(test_status)
          # Abstract
        end

        # Abstract
        # Invoked when a single test is finished
        def end_test(test_status)
          # Abstract
        end

      end
    end
  end
end