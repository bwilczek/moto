module MotoApp
  module Tests
  end
end

module Moto
  class TestGenerator
    
    def initialize(app_dir)
      @app_dir = app_dir
    end
    
    # assuming that target file includes full valid ruby class
    def create(class_name)
      class_name = 'MotoApp::Tests::'+class_name
      a = class_name.underscore.split('/')
      test_path = (a[1..20]+[a[-1]]).join('/')
      
      # TODO: check if this path and constant exists
      require "#{MotoApp::DIR}/#{test_path}"
      test_const = class_name.safe_constantize  
      test_const.new    
    end
    
    def create_module_tree(root_module, next_modules)
      next_module_name = next_modules.shift
      if root_module.const_defined?(next_module_name.to_sym)
        m = root_module.const_get(next_module_name.to_sym)
      else
        m = Module.new
        root_module.const_set(next_module_name.to_sym, m)
      end
      return m if next_modules.empty?
      create_module_tree(m, next_modules)
    end
    
    # assuming that target file includes only content of method 'run' and some magic comments
    def generate(class_name)
      full_class_name = 'MotoApp::Tests::'+class_name
      a = full_class_name.underscore.split('/')
      test_path = (a[1..20]+[a[-1]]).join('/')
      test_path = "#{MotoApp::DIR}/#{test_path}.rb"

      method_body = File.read(test_path) + "\n"

      base = Moto::Test
      base_class_string = method_body.match( /^#\s*BASE_CLASS:\s(\S+)/ )
      unless base_class_string.nil?
        base_class_string = base_class_string[1].strip
        
        a = base_class_string.underscore.split('/')
        base_test_path = a[1..20].join('/')
        
        require "#{MotoApp::DIR}/lib/#{base_test_path}" 
        base = base_class_string.constantize
      end

      # MotoApp::Tests::Login::Short
      consts = full_class_name.split('::')
      class_name = consts.pop

      consts.shift 2 # remove Moto::Test as already defined
      m = create_module_tree(MotoApp::Tests, consts)
      cls = Class.new(base)
      m.const_set(class_name.to_sym, cls)
      
      test_object = cls.new
      test_object.instance_eval( "def run\n  #{method_body} \n end" )
      test_object.static_path = test_path
      test_object
    end
    
  end
end