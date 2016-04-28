module Moto
  module Clients

    class Base
      include Moto::EmptyListener
      include Moto::ForwardContextMethods

      # include Moto::RunnerLogging
      include Moto::TestLogging

      attr_reader :context

      ignore_logging(:handle_test_exception)

      def initialize(context)
        @context = context
      end

      def init
        # abstract
      end

      def handle_test_exception(test, exception)
        # abstract
      end

      # Retrieves specified key's value for current test environment
      # @param [String] key Key which's value will be returned from merged config files
      # @return [String] key's value
      def const(key)
        Moto::Lib::Config.environment_const(key)
      end

    end
  end
end
