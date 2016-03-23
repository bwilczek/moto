require_relative '../exceptions/test_assertion_failed.rb'

module Moto
  module Test
    module Assert

      def assert_equal(a, b)
        assert(a == b, "Arguments should be equal: #{a} != #{b}.")
      end

      def assert_true(b)
        assert(b, 'Logical condition not met, expecting true, given false.')
      end

      def assert_false(b)
        assert(!b, 'Logical condition not met, expecting false, given true.')
      end

      def assert(condition, message)
        if !condition

          if @context.current_test.evaled
            line_number = caller.select { |l| l.match(/\(eval\):\d*:in `run'/) }.first[/\d+/].to_i - 1 # -1 because of added method header in generated class
          else
            line_number = caller.select { |l| l.match(/#{@context.current_test.static_path}:\d*:in `run'/) }.first[/\d+/].to_i - 1
          end

          full_message = "ASSERTION FAILED in line #{line_number}: #{message}"

          raise Exceptions::TestAssertionFailed.new full_message
        end
      end
    end
  end
end
