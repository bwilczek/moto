module Moto
  module Reporting
    module Listeners
      class NoProgress < Base

        def initialize(run_params)
          @displayed_results = 0
          @semaphore = Mutex.new
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
          @semaphore.synchronize do
            @displayed_results += 1

            representation =
                case test_status.results.last.code
                  when Moto::Test::Result::PASSED   then '.'
                  when Moto::Test::Result::FAILURE  then 'F'
                  when Moto::Test::Result::ERROR    then 'E'
                  when Moto::Test::Result::SKIPPED  then 's'
                end

            if @displayed_results%50 != 0
              print representation
            else
              puts representation
            end

          end
        end

      end
    end
  end
end