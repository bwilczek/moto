module Moto
  class ThreadContext
    
    # all resources specific for single thread will be initialized here. E.g. browser session
    attr_reader :runner
    attr_reader :logger
    # attr_reader :log_path
    attr_reader :current_test
    
    def initialize(runner, tests)
      @runner = runner
      @tests = tests
      @clients = {}
      @tests.each do |t|
        t.context = self
      end
      @config = {}
      Dir.glob("config/*.yml").each do |f|
        @config.deep_merge! YAML.load_file(f)
      end
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
        # puts e
        # puts e.backtrace 
        return nil
      end
    end
    
    def const(key)
      key = key.to_s
      key = "#{@current_test.env.to_s}.#{key}" if @current_test.env != :__default
      code = if key.include? '.'
        "@config#{key.split('.').map{|a| "['#{a}']" }.join('')}"
      else
        "@config['#{key}']"
      end
      begin
        v = eval code
        raise if v.nil?
      rescue
        raise "There is no const defined for key: #{key}. Environment: #{ (@current_test.env == :__default) ? '<none>' : @current_test.env }"
      end
      v
    end
    
    def run
      @tests.each do |test|
        # remove log files from previous execution
        Dir.glob("#{test.dir}/*.log").each {|f| File.delete f }
        max_attempts = @runner.my_config[:max_attempts] || 1
        @runner.environments.each do |env|
          params_path = "#{test.dir}/#{test.filename}.yml"
          params_all = [{}]
          params_all = YAML.load_file(params_path) if File.exists?(params_path)
          # or convert keys to symbols?
          # params_all = YAML.load_file(params_path).map{|h| Hash[ h.map{|k,v| [ k.to_sym, v ] } ] } if File.exists?(params_path)
          params_all.each_with_index do |params, params_index|
            # TODO: add filtering out params that are specific to certain envs
            (1..max_attempts).each do |attempt|
              test.init(env, params, params_index)
              # TODO: log path might be specified (to some extent) by the configuration
              test.log_path = "#{test.dir}/#{test.name.gsub(/\s+/, '_').gsub('::', '_').gsub('/', '_')}.log"
              @logger = Logger.new(File.open(test.log_path, File::WRONLY | File::TRUNC | File::CREAT))
              # TODO: make logger level configurable
              @logger.level = @runner.my_config[:log_level]
              @current_test = test
              @runner.listeners.each { |l| l.start_test(test) }
              @clients.each_value { |c| c.start_test(test) }
              test.before
              @logger.info "Start: #{test.name} attempt #{attempt}/#{max_attempts}"
              begin
                test.run
              rescue Exceptions::TestForcedPassed, Exceptions::TestForcedFailure, Exceptions::TestSkipped => e
                logger.info(e.message)
                @runner.result.add_error(test, e)
              rescue Exception => e  
                @logger.error("#{e.class.name}: #{e.message}")  
                @logger.error(e.backtrace.join("\n"))
                @runner.result.add_error(test, e)
              end 
              test.after
              @clients.each_value { |c| c.end_test(test) }
              # HAX: running end_test on results now, on other listeners after logger is closed
              @runner.listeners.first.end_test(test)
              @logger.info("Result: #{test.result}")
              @logger.close
              @runner.listeners[1..-1].each { |l| l.end_test(test) }
              break unless [Result::FAILURE, Result::ERROR].include? test.result
            end # RETRY
          end
        end
      end
      @clients.each_value { |c| c.end_run }
    end
  
  end
end