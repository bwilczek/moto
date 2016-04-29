module Moto
  module Lib
    class Config

      def self.load_configuration
        if File.exists? "#{MotoApp::DIR}/config/moto.rb"
          @@moto = eval(File.read("#{MotoApp::DIR}/config/moto.rb"))

          @@env_consts = {}
          Dir.glob('config/*.yml').each do |f|
            @@env_consts.deep_merge! YAML.load_file(f)
          end

        else
          raise "Config file (config/moto.rb) not present.\nDoes current working directory contain Moto application?"
        end
      end

      # @return [Hash] Hash representing data from MotoApp/config/moto.rb file
      def self.moto
        @@moto
      end

      #
      # @param [String] key Name of the key which's value is to be retrieved
      # @return [String] Value of the key
      def self.environment_const(key)
        key = key.to_s
        env = Thread.current['test_environment']

        if env != :__default
          key = "#{env.to_s}.#{key}"
        end

        code = if key.include? '.'
                 "@@env_consts#{key.split('.').map { |a| "['#{a}']" }.join('')}"
               else
                 "@@env_consts['#{key}']"
               end

        begin
          value = eval code
          raise if value.nil?
        rescue
          raise "There is no const defined for key: #{key}. Environment: #{ (env == :__default) ? '<none>' : env }"
        end

        value
      end

    end
  end
end