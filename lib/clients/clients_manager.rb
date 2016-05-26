module Moto
  module Lib
    module Clients
      class ClientsManager

        attr_reader :clients

        def initialize
          @clients = {}
        end

        def client(name)
          return @clients[name] if @clients.key? name

          name_app = 'MotoApp::Lib::Clients::' + name
          name_moto = 'Moto::Clients::' + name

          client = try_client(name_app, "#{MotoApp::DIR}/")
          if client
            @clients[name] = client
            return client
          end

          client = try_client(name_moto, "#{Moto::DIR}/lib/")
          if client
            @clients[name] = client
            return client
          end

          raise "Could not find client class for name: #{name}"
        end

        def try_client(name, dir)
            client_path = name.underscore.split('/')[1..-1].join('/')

            if File.file?(dir + client_path + '.rb')
              require dir + client_path
              client_const = name.constantize
              instance = client_const.new
              instance.start_run
              instance
            else
              nil
            end
        end
        private :try_client

      end
    end
  end
end