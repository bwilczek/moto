module Moto
  class ThreadContext
    
    # all resources specific for single thread will be initialized here. E.g. browser session
    attr_reader :runner
    attr_reader :logger
    attr_reader :log_path
    attr_reader :current_test
    
    def initialize(runner, tests)
      @runner = runner
      @tests = tests
      @clients = {}
      @tests.each do |t|
        t.context = self
      end
      # TODO: add all *.yml files from that dir
      @config = YAML.load_file("#{MotoApp::DIR}/config/const.yml")
    end
    
    def client(name)
      return @clients[name] if @clients.key? name
      
      name_app = 'MotoApp::Clients::' + name
      name_moto = 'Moto::Clients::' + name
      
      c = try_client(name_app, "#{MotoApp::DIR}/lib")
      unless c.nil?
        @clients[name] = c
        return c
      end

      c = try_client(name_moto, "#{Moto::DIR}/lib")
      unless c.nil?
        @clients[name] = c
        return c
      end
      raise "Could not find client class for name #{name}"
    end
    
    def try_client(name, dir)
      begin      
        a = name.underscore.split('/')
        client_path = a[1..20].join('/')
        require "#{dir}/#{client_path}"
        client_const = name.constantize
        instance = client_const.new(self)
        instance.init
        instance.start_run
        instance.start_test(@current_test)
        return instance
      rescue Exception => e  
        return nil
      end
    end
    
    def const(key)
      key = "#{@current_test.env.to_s}.#{key}" if @current_test.env != :__default
      code = "@config#{key.split('.').map{|a| "['#{a}']" }.join('')}"
      begin
        v = eval code
        raise if v.nil?
      rescue
        raise "There is no const defined for key: #{key}"
      end
      v
    end
    
    def run
      @tests.each do |test|
        # remove log files from previous execution
        FileUtils.rm_rf Dir.glob("#{test.dir}/*.log")
        @runner.environments.each do |env|
          params_path = "#{test.dir}/#{test.filename}.yml"
          params_all = [{}]
          params_all = YAML.load_file(params_path) if File.exists?(params_path)
          # or convert keys to symbols?
          # params_all = YAML.load_file(params_path).map{|h| Hash[ h.map{|k,v| [ k.to_sym, v ] } ] } if File.exists?(params_path)
          params_all.each do |params|
            # TODO: add filtering out params that are specific to certain envs
            test.init(env, params)
            # TODO: log path might be specified (to some extent) by the configuration
            @log_path = "#{test.dir}/#{test.name.gsub(/\s+/, '_').gsub('::', '_').gsub('/', '_')}.log"
            @logger = Logger.new(File.open(@log_path, File::WRONLY | File::TRUNC | File::CREAT))
            # TODO: make logger level configurable
            @logger.level = @runner.my_config[:log_level]
            @current_test = test
            @runner.listeners.each { |l| l.start_test(test) }
            @clients.each_value { |c| c.start_test(test) }
            test.before
            @logger.info "Start: #{test.name}"
            begin
              test.run
            rescue Exception => e  
              @logger.error("#{e.class.name}: #{e.message}")  
              @logger.error(e.backtrace.join("\n"))
              @runner.result.add_error(test, e)
            end 
            test.after
            @clients.each_value { |c| c.end_test(test) }
            @runner.listeners.each { |l| l.end_test(test) }
            @logger.info("Result: #{test.result}")
            @logger.close
          end
        end
      end
      @clients.each_value { |c| c.end_run }
    end
  
  end
end