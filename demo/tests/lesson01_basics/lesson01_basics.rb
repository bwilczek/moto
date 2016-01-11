# Line below shows how to tag tests
# MOTO_TAGS: demo, regression

logger.info "It's my party."

# pass("I like it.")            # instant finish as PASSED 
# fail("I don't like it.")      # instant finish as FAILURE
# skip("Jump, jump!")           # instant finish as SKIPPED
# raise("Something is wrong!")  # instant finish as ERROR

assert_equal(2+2, 4)
