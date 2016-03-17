module Moto
  module Reporting
    module Listeners
      class Base

        def start_run(run_status)
          # abstract
        end

        def end_run(run_status)
          # abstract
        end

        def start_test(test_status)
          # abstract
        end

        def end_test(test_status)
          # abstract
        end
      end
    end
  end
end