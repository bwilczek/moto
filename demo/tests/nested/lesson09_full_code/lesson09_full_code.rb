# FULL_CODE
# MOTO_TAGS: demo, regression

module MotoApp
  module Tests
    module Nested
      class Lesson09FullCode < Moto::Test
        
        def run
          logger.info "It's my party."
          assert_equal(2+2, 4)
        end
        
      end
    end
  end
end
