# Line below shows how to tag tests

# MOTO_TAGS: demo, regression
# DESC: Description line 1
# DESC: Description line 2

# Please pay attention to module vs folder structure.

module MotoApp
  module Tests
    class ExemplaryMotoTest < Moto::Test::Base

      def before
        # optional
      end

      def run
        assert(2 + 2 == 4, 'First grade math requirements not met.')

        # See demo/config/environments for examples how env specific variables are set
        assert(!const('section_name1.env_specific_key').nil?, 'Env specific param should not be nil.')

        # pass("I like it.")            # instant finish as PASSED
        # fail("I don't like it.")      # instant finish as FAILURE
        # skip("Jump, jump!")           # instant finish as SKIPPED
        # raise("Something is wrong!")  # instant finish as ERROR
      end

      def after
        # optional
      end

    end
  end
end

