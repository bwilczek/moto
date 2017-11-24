module Moto
  module Reporting
    module Listeners
      class SummaryOnly < Base

        def start_run
        end

        def end_run(run_status)
          puts ''
          puts "FINISHED: #{run_status.to_s}, duration: #{Time.at(run_status.duration).utc.strftime("%H:%M:%S")}"
          puts "Tests executed: #{run_status.tests_all.length}"
          puts "  Passed:       #{run_status.tests_passed.length}"
          puts "  Failure:      #{run_status.tests_failed.length}"
          puts "  Error:        #{run_status.tests_error.length}"
          puts "  Skipped:      #{run_status.tests_skipped.length}"
        end

        def start_test(test_status, test_metadata)
        end

        def end_test(test_status)
        end

      end
    end
  end
end