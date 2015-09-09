module Moto
  module ForwardContextMethods

      def client(name)
        @context.client(name)
      end
      
      def logger
        @context.logger
      end
      
      def const(key)
        @context.const(key)
      end
      
      def current_test
        @context.current_test
      end
   
  end
end