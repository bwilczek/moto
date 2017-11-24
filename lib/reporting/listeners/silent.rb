module Moto
  module Reporting
    module Listeners
      class Silent < Base

        def start_run
        end

        def end_run(run_status)
        end

        def start_test(test_status, test_metadata)
        end

        def end_test(test_status)
        end

      end
    end
  end
end