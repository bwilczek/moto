module Moto
  module Listeners
    class Console < Base

      def start_run
        puts "START"
      end
      
      def end_run
        puts ""
        puts "FINISHED: #{@runner.result.summary[:result]}, duration: #{Time.at(@runner.result.summary[:duration]).utc.strftime("%H:%M:%S")}"
        puts "Tests executed: #{@runner.result.summary[:cnt_all]}"
        puts "  Passed:       #{@runner.result.summary[:cnt_passed]}"
        puts "  Failure:      #{@runner.result.summary[:cnt_failure]}"
        puts "  Error:        #{@runner.result.summary[:cnt_error]}"
        puts "  Skipped:      #{@runner.result.summary[:cnt_skipped]}"
      end

      def start_test(test)
        print test.name
      end
  
      def end_test(test)
        puts "\t#{@runner.result[test.name][:result]}"
      end

    end
  end
end