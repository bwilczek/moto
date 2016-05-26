module Moto
  class Page

    include Moto::TestLogging

    ignore_logging :const
    ignore_logging :session

    # Returns Capybara's session by means of on-the-fly client&session creation.
    def session
      Thread.current['clients_manager'].client('Website').session
    end

    def raise_unless_loaded
      raise "Invalid state: page #{self.class.name} is not loaded." unless loaded?
    end

    # Retrieves specified key's value for current test environment
    # @param [String] key Key which's value will be returned from merged config files
    # @return [String] key's value
    def const(key)
      Moto::Lib::Config.environment_const(key)
    end

  end
end