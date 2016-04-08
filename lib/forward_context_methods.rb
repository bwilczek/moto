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
      
      def test
        @context.test
      end
   
  end
end