module Moto
  module Reporting
    module Listeners

      # Base class for listeners that report results of testing 'outside' of the application.
      class Base

        attr_reader :config
        attr_reader :custom_run_name

        # @param [Hash] config
        # @param [String] custom_run_name Optional run name to be passed to listeners
        def initialize(config, custom_run_name = '')
          @config = config
          @custom_run_name = custom_run_name
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