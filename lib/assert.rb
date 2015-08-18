module Moto
  module Assert

    def assert_equal(a, b)
      assert(a==b, "Arguments should be equal: #{a} != #{b}")
    end

    def assert_true(b)
      assert(b, "Logical condition not met, expecting true, given false.")
    end

    def assert(condition, message)
      unless condition
        @context.runner.result.add_failure(self, message)
        logger.error("ASSERTION FAILED: #{message}")
      end
    end

  end
end
