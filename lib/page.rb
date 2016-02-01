module Moto

  class Page

    include Moto::TestLogging
    include Moto::ForwardContextMethods

    ignore_logging :const
    ignore_logging :session

    attr_reader :website
    attr_reader :context

    def initialize(website)
      @website = website
      @context = @website.context
    end

    def page(p)
      @context.client(@website.class.name.split('::').pop).page(p)
    end

    def raise_unless_loaded
      raise "Invalid state: page #{self.class.name} is not loaded." unless loaded?
    end

  end
end