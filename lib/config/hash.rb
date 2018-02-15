module Moto
  module Config
    # Purpose of this class is to enable developers of Moto-reliant apps to be able to monkey patch their custom methods
    # to data structure (this) that holds, retrieves and modifies env config data
    class Hash < Hash

    end
  end
end