require 'base'

module Moto
  module Reporting
    module Listeners
      class Console < Base

        def start_run
         # puts 'START'
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

        def end_test(test_status)
          puts "\n#{test_status.name}\n\t#{test_status.results.last.message}"
        end

      end
    end
  end
end