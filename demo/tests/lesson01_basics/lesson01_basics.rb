# Line below shows how to tag tests

# MOTO_TAGS: demo, regression

module MotoApp
  module Tests
    class Lesson09FullCode < Moto::Test::Base

      def run
        assert_equal(2+2, 4)

        # pass("I like it.")            # instant finish as PASSED
        # fail("I don't like it.")      # instant finish as FAILURE
        # skip("Jump, jump!")           # instant finish as SKIPPED
        # raise("Something is wrong!")  # instant finish as ERROR
      end

    end
  end
end

