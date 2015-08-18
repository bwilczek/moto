module Moto
  module Listeners
    class ConsoleDots < Base

      def start_run
      end
      
      def end_run
        puts ""
        puts "FINISHED: #{@runner.result.summary[:result]}, duration: #{Time.at(@runner.result.summary[:duration]).utc.strftime("%H:%M:%S")}"
        puts "Tests executed: #{@runner.result.summary[:cnt_all]}"
        puts "  Passed:       #{@runner.result.summary[:cnt_passed]}"
        puts "  Failure:      #{@runner.result.summary[:cnt_failure]}"
        puts "  Error:        #{@runner.result.summary[:cnt_error]}"
      end

      def start_test(test)
      end
  
      def end_test(test)
        print case @runner.result[test.name][:result]
        when :passed then "."
        when :failure then "F"
        when :error then "E"
        end 
      end

    end
  end
end