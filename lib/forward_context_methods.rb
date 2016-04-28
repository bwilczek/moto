module Moto
  module ForwardContextMethods
      # Access client object instance for given class name.
      def client(name)
        @context.client(name)
      end

      # Write message to test execution log file. See Ruby Logger class for details.
      def logger
        @context.logger
      end

      # Access currently executed test
      def test
        @context.test
      end
   
  end
end