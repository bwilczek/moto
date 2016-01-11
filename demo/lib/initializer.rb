module MotoApp
  class Initializer < Moto::Initializer

    def init
      # this method is executed prior to all tests
      # add your hacks / monkey patches to classes of Clients, Pages or whatever necessary here
      # puts @runner.listeners.count
    end

  end
end