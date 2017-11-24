require 'active_support'

module Moto
  module Lib
    class Config

      # @return [String] String representing the name of the current environment
      def self.environment
        @@environment
      end

      # @param [String] environment Sets a string that will represent environment in configuration, on which
      #                             various settings will depend, for example env. constants
      def self.environment=(environment)
        @@environment = environment
      end

      # Loads configuration for whole test run and files responsible for environmental constants.
      # @param [String] config_name Name of the main Moto/MotoApp config to be loaded. Without extension.
      # @param [String] env Name of the env config to be loaded in addition to /config/environments/common. Without extension.
      def self.load_configuration(config_name, env)
        config_path = "#{MotoApp::DIR}/config/#{config_name}.rb"

        if File.exists?(config_path)
          @@moto = eval(File.read(config_path))

          # Try reading constants that are common for all environments
          begin
            common_constants = eval(File.read('config/environments/common.rb'))
          rescue
            common_constants = {}
          end

          # Try reading constants specific to current environment
          if env
            self.environment = env

            begin
              environment_constants = eval(File.read("config/environments/#{@@environment}.rb"))
            rescue
              environment_constants = {}
            end
          end

          if environment_constants
            @@env_consts = common_constants.deep_merge(environment_constants)
          end

        else
          raise "Config file: #{config_path} does not exist.\nDoes current working directory contain Moto application?"
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

        code = if key.include? '.'
                 "@@env_consts#{key.split('.').map { |a| "[:#{a}]" }.join('')}"
               else
                 "@@env_consts[:#{key}]"
               end

        begin
          value = eval(code)
          raise if value.nil?
        rescue
          raise "There is no const defined for key: #{key}."
        end

        value
      end

    end
  end
end