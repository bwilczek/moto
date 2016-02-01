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

    end
  end
end
