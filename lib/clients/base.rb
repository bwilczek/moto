module Moto
  module Clients

    class Base
      include Moto::EmptyListener

      # include Moto::RunnerLogging
      include Moto::TestLogging

      ignore_logging(:handle_test_exception)

      def handle_test_exception(test, exception)
        # abstract
      end

      # Retrieves specified key's value for current test environment
      # @param [String] key Key which's value will be returned from merged config files
      # @return [String] key's value
      def const(key)
        Moto::Lib::Config.environment_const(key)
      end

      # Access client defined in Moto or MotoApp via it's name
      def client(name)
        Thread.current['clients_manager'].client(name)
      end

    end
  end
end
