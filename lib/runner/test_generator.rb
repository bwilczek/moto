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

      # assuming that target file includes only content of method 'run' and some magic comments
      def generate(test_path_absolute)
        method_body = File.read(test_path_absolute) + "\n"

        full_code = !!method_body.match(/^#\s*FULL_CODE\s+/)

        if full_code
          generate_for_full_class_code(test_path_absolute)
        else
          generate_for_run_body(test_path_absolute, method_body)
        end
      end
      private :generate

      # Generates test instances, based on fully defined class file
      # @return [Moto::Test::Base]
      def generate_for_full_class_code(test_path_absolute)
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
        test_object.evaled = false
        test_object
      end
      private :generate_for_full_class_code

      def create_module_tree(root_module, next_modules)
        return root_module if next_modules.empty?
        next_module_name = next_modules.shift
        if root_module.const_defined?(next_module_name.to_sym)
          m = root_module.const_get(next_module_name.to_sym)
        else
          m = Module.new
          root_module.const_set(next_module_name.to_sym, m)
        end
        create_module_tree(m, next_modules)
      end
      private :create_module_tree

      # Generates test instances, based on a text file with ruby code that has to be injected into run() method
      # @return [Moto::Test::Base]
      def generate_for_run_body(test_path_absolute, method_body)
        base = Moto::Test::Base
        base_class_string = method_body.match(/^#\s*BASE_CLASS:\s(\S+)/)
        unless base_class_string.nil?
          base_class_string = base_class_string[1].strip

          a = base_class_string.underscore.split('/')
          base_test_path = a[1..-1].join('/')

          require "#{MotoApp::DIR}/#{base_test_path}"
          base = base_class_string.constantize
        end

        # MotoApp::Tests::Login::Short
        consts = test_path_absolute.camelize.split('Tests::')[1].split('::')
        consts.pop
        class_name = consts.pop

        m = create_module_tree(MotoApp::Tests, consts)
        cls = Class.new(base)
        m.const_set(class_name.to_sym, cls)

        test_object = cls.new
        test_object.instance_eval("def run\n  #{method_body} \n end")
        test_object.static_path = test_path_absolute
        test_object.evaled = true
        test_object
      end
      private :generate_for_run_body

    end
  end
end