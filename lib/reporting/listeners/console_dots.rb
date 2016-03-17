module Moto
  module Reporting
    module Listeners
      class ConsoleDots < Base

        def end_run(run_status)
          puts ""
          puts ""
          puts "FINISHED: #{run_status.result}, duration: #{Time.at(run_status.duration).utc.strftime("%H:%M:%S")}"
          puts "Tests executed: #{@runner.result.summary[:cnt_all]}"
          puts "  Passed:       #{@runner.result.summary[:cnt_passed]}"
          puts "  Failure:      #{@runner.result.summary[:cnt_failure]}"
          puts "  Error:        #{@runner.result.summary[:cnt_error]}"
          puts "  Skipped:      #{@runner.result.summary[:cnt_skipped]}"

          if @runner.result.summary[:cnt_failure] > 0
            puts ""
            puts "FAILURES: "
            @runner.result.summary[:tests_failure].each do |test_name, data|
              puts test_name
              puts "\t#{data[:failures].join("\n\t")}"
              puts ""
            end
          end

          if @runner.result.summary[:cnt_error] > 0
            puts ""
            puts "ERRORS: "
            @runner.result.summary[:tests_error].each do |test_name, data|
              puts test_name
              puts "\t#{data[:error]}"
              puts ""
            end
          end

          if @runner.result.summary[:cnt_skipped] > 0
            puts ''
            puts 'SKIPPED: '
            @runner.result.summary[:tests_skipped].each do |test_name, data|
              puts test_name
              puts "\t#{data[:error]}"
              puts ''
            end
          end
        end

        def start_test(test_status)
        end

        def end_test(test)
          print case test_status.result
          when :passed then '.'
          when :failure then 'F'
          when :error then 'E'
          when :skipped then 's'
          end
        end

      end
    end
  end
end