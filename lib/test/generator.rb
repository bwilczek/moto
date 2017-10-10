require_relative 'base'

module MotoApp
  module Tests
  end
end

module Moto
  module Test
    class Generator

      def initialize
        @internal_counter = 0
      end

      # Method returns an array of test instances that represent all variants (parameter sets from test's config).
      #   Example: A test with no config file will be returned as an array with single Moto::Test::Base in it.
      #   Example: A test with a config file and 2 sets of parameters there will be returned as array with two elements.
      #
      # @param [Moto::Test::Metadata] test_metadata Metadata that describes test to be instantiated
      # @param [Integer] variants_limit Limit how many params will be parsed per test. Default: 0 (no limit)
      # @return [Array] An array of [Moto::Test::Base] descendants
      #                 each entry is a Test with set of parameters injected
      def get_test_with_variants(test_metadata, variants_limit = 0)
        variantize(test_metadata, variants_limit)
      end

      # Converts test's path to an array of Moto::Base::Test instances that represent all test variants (params)
      #
      # *IMPORTANT*
      # Config files with ruby code will be evaluated thus if you use any classes in them
      # they must be required prior to that. That might be done in overloaded app's initializer.
      #
      # @param [Moto::Test::Metadata] test_metadata Metadata that describes test to be instantiated, contains path to test
      # @param [Integer] variants_limit Limit how many params will be parsed per test.
      # @return [Array] array of already initialized test's variants
      def variantize(test_metadata, variants_limit)
        variants = []

        # TODO CHANGED TEMPORARY
        #params_path = test_path_absolute.sub(/\.rb\z/, '')
        params_directory = File.dirname(test_metadata.test_path).to_s + '/params/'

        # Depending on param_name being provided or not filter files in param directory in appropriate way
        if config[:param_name]
          params_directory << "*#{config[:param_name]}*.param"
        else
          params_directory << '*.param'
        end

        param_files_paths = Dir.glob(params_directory)

        # If param name is not specified then it's possible to run a test without params - they might not be there at all,
        # but when param name is provided only matching ones need to be executed.
        if config[:param_name]
          param_files_paths = [] if param_files_paths.empty?
        else
          param_files_paths = [nil] if param_files_paths.empty?
        end

        param_files_paths.each do |params_path|

          # TODO Name/logname/displayname
          test = generate(test_metadata)
          test.init(params_path)
          test.log_path = "#{File.dirname(test_metadata.test_path).to_s}/logs/#{test.name.gsub(/[^0-9A-Za-z.\-]/, '_')}.log"
          @internal_counter += 1

          variants << test

          # Break if limit of parametrized variants has been reached
          if variants_limit > 0 && variants.length == variants_limit
            break
          end
        end

        variants
      end
      private :variantize

      # Generates test instances
      # @return [Moto::Test::Base]
      def generate(test_metadata)

        test_path = test_metadata.test_path

        # Checking if it's possible to create test based on provided path. In case something is wrong with
        # modules structure in class itself Moto::Test::Base will be instantized with raise injected into its run()
        # so we can have proper reporting and summary even if the test doesn't execute.
        begin
          require test_path
          class_name = test_path.gsub("#{MotoApp::DIR}/", 'moto_app/').camelize.chomp('.rb').constantize
          test_object = class_name.new
        rescue NameError => e
          class_name = Moto::Test::Base
          test_object = class_name.new

          error_message = "ERROR: Invalid test: #{test_path.gsub("#{MotoApp::DIR}/", 'moto_app/').camelize.chomp('.rb')}.\nMESSAGE: #{e}"
          inject_error_to_test(test_object, error_message)
        end

        test_object.static_path = test_path
        test_object.metadata = test_metadata
        test_object
      end
      private :generate

      # Injects raise into test.run so it will report an error when executed
      # @param [Moto::Test::Base] test An instance of test that is supposed to be modified
      # @param [String] error_message Message to be attached to the raised exception
      def inject_error_to_test(test, error_message)
        class << test
          attr_accessor :injected_error_message

          def run
            raise injected_error_message
          end
        end

        test.injected_error_message = error_message
      end

      # @return [Hash] Hash with config for test generator
      def config
        Moto::Lib::Config.moto[:test_generator]
      end
      private :config

    end
  end
end