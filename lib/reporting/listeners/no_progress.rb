module Moto
  module Reporting
    module Listeners
      class NoProgress < Base

        def start_run
        end

        def end_run(run_status)
          puts ''
          puts ''
          puts "FINISHED: #{run_status.to_s}, duration: #{Time.at(run_status.duration).utc.strftime("%H:%M:%S")}"
          puts "Tests executed: #{run_status.tests_all.length}"
          puts "  Passed:       #{run_status.tests_passed.length}"
          puts "  Failure:      #{run_status.tests_failed.length}"
          puts "  Error:        #{run_status.tests_error.length}"
          puts "  Skipped:      #{run_status.tests_skipped.length}"

          if run_status.tests_failed.length > 0
            puts ''
            puts 'FAILURES: '
            run_status.tests_failed.each do |test_status|
              puts test_status.display_name
              puts "\t" + test_status.results.last.failures.join("\n\t")
              puts ''
            end
          end

          if run_status.tests_error.length > 0
            puts ''
            puts 'ERRORS: '
            run_status.tests_error.each do |test_status|
              puts test_status.display_name
              puts "\t" + test_status.results.last.message
              puts ''
            end
          end

          if run_status.tests_skipped.length > 0
            puts ''
            puts 'SKIPPED: '
            run_status.tests_skipped.each do |test_status|
              puts test_status.display_name
              puts "\t" + test_status.results.last.message
              puts ''
            end
          end

        end

        def start_test(test_status, test_metadata)
        end

        def end_test(test_status)
        end

      end
    end
  end
end