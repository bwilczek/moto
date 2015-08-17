module Moto

  class Page

    include Moto::TestLogging
    
    ignore_logging :const
    ignore_logging :session

    def initialize(website)
      @website = website
      @context = @website.context
    end
    
    def const(key)
      @website.context.const(key)
    end
    
    def session
      @website.session
    end
    
    def page(p)
      @context.client(@website.class.name.split('::').pop).page(p)
    end

    def raise_unless_loaded
      raise "Invalid state: page #{self.class.name} is not loaded." unless loaded?
    end
    
  end
end