module Moto
  module Reporting
    module Listeners
      class KernelCode < Base

        def self.code
          @@code
        end

        # Invoked when whole batch of tests ends
        def end_run(run_status)

          code = 0

          if run_status.tests_error.length > 0
            code += 0b100
          end

          if run_status.tests_failed.length > 0
            code += 0b010
          end

          if run_status.tests_skipped.length > 0
            code += 0b001
          end

          @@code = code
        end

      end
    end
  end
end