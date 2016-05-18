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
      def self.load_configuration
        if File.exists? "#{MotoApp::DIR}/config/moto.rb"
          @@moto = eval(File.read("#{MotoApp::DIR}/config/moto.rb"))

          # Try reading constants that are common for all environments
          begin
            common_constants = eval(File.read('config/environments/common.rb'))
          rescue
            common_constants = {}
          end

          # Try reading constants specific to current environment
          begin
            environment_constants = eval(File.read("config/environments/#{@@environment}.rb"))
          rescue
            environment_constants = {}
          end

          @@env_consts = common_constants.deep_merge(environment_constants)

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