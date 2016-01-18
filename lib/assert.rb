module Moto
  module Assert

    def assert_equal(a, b)
      assert(a==b, "Arguments should be equal: #{a} != #{b}.")
    end

    def assert_true(b)
      assert(b, "Logical condition not met, expecting true, given false.")
    end

    def assert(condition, message)
      unless condition
        
        line_number = if @context.current_test.evaled 
          caller.select{ |l| l.match(/\(eval\):\d*:in `run'/) }.first[/\d+/].to_i - 1 # -1 because of added method header in generated class
        else
          line_number = caller.select{ |l| l.match(/#{@context.current_test.static_path}:\d*:in `run'/) }.first[/\d+/].to_i - 1
        end

        full_message = "ASSERTION FAILED in line #{line_number}: #{message}"
        @context.runner.result.add_failure(self, full_message)
        logger.error(full_message)
      end
    end

  end
end
