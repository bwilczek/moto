module MotoApp
  module Tests
  end
end

module Moto
  class TestGenerator

    def initialize(test_paths_absolute)
      @test_paths_absolute = test_paths_absolute
    end

    # @return [Array] An array of [Moto::Test::Base] decendants
    #                 each entry is a Test with set of Parameters injected
    def get_test_with_variants
      test_path = @test_paths_absolute.shift
      # TODO: Generate test + params variants once params are removed from ThreadContext
      test_path.nil? ? nil : [generate(test_path)]
    end

    # assuming that target file includes only content of method 'run' and some magic comments
    def generate(test_path_absolute)
      method_body = File.read(test_path_absolute) + "\n"

      full_code = !! method_body.match( /^#\s*FULL_CODE\s+/ )

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
      require test_path_absolute

      test_object = nil

      # Checking if it's possible to create test based on provided path. In case something is wrong with
      # modules structure in class itself Moto::Test::Base will be instantized with raise injected into its run()
      # so we can have proper reporting and summary even if the test doesn't execute.
      begin
        class_name = test_path_absolute.gsub("#{MotoApp::DIR}/",'moto_app/').camelize.chomp('.rb').constantize
        test_object = class_name.new
      rescue NameError
        class_name = Moto::Test::Base
        test_object = class_name.new

        class << test_object
          attr_accessor :custom_name

          def run
            raise "ERROR: Invalid module structure: #{custom_name}"
          end
        end

        test_object.custom_name = test_path_absolute.gsub("#{MotoApp::DIR}/",'moto_app/').camelize.chomp('.rb')
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
      base_class_string = method_body.match( /^#\s*BASE_CLASS:\s(\S+)/ )
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
      test_object.instance_eval( "def run\n  #{method_body} \n end" )
      test_object.static_path = test_path_absolute
      test_object.evaled = true        
      test_object
    end
    private :generate_for_run_body

  end
end