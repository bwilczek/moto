module Moto
  module Clients

    class Base
      include Moto::EmptyListener
      include Moto::ForwardContextMethods

      # include Moto::RunnerLogging
      include Moto::TestLogging

      attr_reader :context

      def initialize(context)
        @context = context
      end

      def init
        # abstract
      end

      def save_screenshot(path)
        @context.logger.info "Client [#{self.class}] doesn't support screenshots"
      end

    end
  end
end
