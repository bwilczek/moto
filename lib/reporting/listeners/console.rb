module Moto
  module Reporting
    module Listeners
      class Console < Base

        def start_run
          puts 'START'
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

        def start_test(test_status)
          print test_status.name
        end

        def end_test(test_status)
          puts "\t#{test_status.to_s}"
        end

      end
    end
  end
end