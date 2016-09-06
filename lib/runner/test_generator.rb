module MotoApp
  module Tests
  end
end

module Moto
  module Runner
    class TestGenerator

      def initialize
        @internal_counter = 0
      end

      # Method returns an array of test instances that represent all variants (parameter sets from test's config).
      #   Example: A test with no config file will be returned as an array with single Moto::Test::Base in it.
      #   Example: A test with a config file and 2 sets of parameters there will be returned as array with two elements.
      #
      # @param [String] test_path_absolute Path to the test that is about to be instantiated.
      # @return [Array] An array of [Moto::Test::Base] decendants
      #                 each entry is a Test with set of parameters injected
      def get_test_with_variants(test_path_absolute)
        test_path_absolute ? variantize(test_path_absolute) : nil
      end

      # Converts test's path to an array of Moto::Base::Test instances that represent all test variants (params)
      #
      # *IMPORTANT*
      # Config files with ruby code will be evaluated thus if you use any classes in them
      # they must be required prior to that. That might be done in overloaded app's initializer.
      #
      # @param [String] test_path_absolute Path to the file with test
      # @return [Array] array of already initialized test's variants
      def variantize(test_path_absolute)
        variants = []

          # TODO CHANGED TEMPORARY
          #params_path = test_path_absolute.sub(/\.rb\z/, '')
          params_directory = File.dirname(test_path_absolute).to_s + '/params/**'
          param_files_paths = Dir.glob(params_directory)
          param_files_paths = [nil] if param_files_paths.empty?

          #TODO Fix
          param_files_paths.each_with_index do |params_path, params_index|

            #TODO environment support
            # Filtering out param sets that are specific to certain envs
            # unless params['__env'].nil?
            #   allowed_envs = params['__env'].is_a?(String) ? [params['__env']] : params['__env']
            #   next unless allowed_envs.include?(Moto::Lib::Config.environment)
            # end

            #TODO Name/logname/displayname
            test = generate(test_path_absolute)
            test.init(params_path, params_index, @internal_counter)
            test.log_path = "#{File.dirname(test_path_absolute).to_s}/logs/#{test.name.gsub(/[^0-9A-Za-z.\-]/, '_')}.log"
            @internal_counter += 1

            variants << test
          end

        variants
      end
      private :variantize

      # Generates test instances
      # @return [Moto::Test::Base]
      def generate(test_path_absolute)

        # Checking if it's possible to create test based on provided path. In case something is wrong with
        # modules structure in class itself Moto::Test::Base will be instantized with raise injected into its run()
        # so we can have proper reporting and summary even if the test doesn't execute.
        begin
          require test_path_absolute
          class_name = test_path_absolute.gsub("#{MotoApp::DIR}/", 'moto_app/').camelize.chomp('.rb').constantize
          test_object = class_name.new
        rescue NameError => e
          class_name = Moto::Test::Base
          test_object = class_name.new

          error_message = "ERROR: Invalid test: #{test_path_absolute.gsub("#{MotoApp::DIR}/", 'moto_app/').camelize.chomp('.rb')}.\nMESSAGE: #{e}"
          inject_error_to_test(test_object, error_message)
        end

        test_object.static_path = test_path_absolute
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

    end
  end
end