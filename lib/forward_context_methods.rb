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

      # Read const value specific for current environment from `config/const.yml` file
      def const(key)
        @context.const(key)
      end

      # Access currently executed test
      def test
        @context.test
      end
   
  end
end