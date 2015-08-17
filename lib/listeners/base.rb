module Moto
  module Listeners
    class Base
      
      def initialize(runner)
        @runner=runner
      end
      
      def start_run
        # abstract
      end
      
      def end_run
        # abstract
      end
      
      def start_test(test)
        # abstract
      end
  
      def end_test(test)
        # abstract
      end      
    end
  end
end