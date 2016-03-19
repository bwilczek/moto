module Moto
  module Reporting
    module Listeners

      # Base class for listeners that report results of testing 'outside' of the application.
      class Base

        # Abstract
        # Invoked when whole batch of tests starts
        def start_run
          raise('Abstract function. Override before using.')
        end

        # Abstract
        # Invoked when whole batch of tests ends
        def end_run(run_status)
          raise('Abstract function. Override before using.')
        end

        # Abstract
        # Invoked when a single test is started
        def start_test(test_status)
          raise('Abstract function. Override before using.')
        end

        # Abstract
        # Invoked when a single test is finished
        def end_test(test_status)
          raise('Abstract function. Override before using.')
        end

      end
    end
  end
end