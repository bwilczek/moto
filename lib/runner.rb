module Moto
  class Runner

    attr_reader :result
    attr_reader :listeners
    attr_reader :logger
    attr_reader :environments
    attr_reader :assert
    attr_reader :config
    attr_reader :name

    def initialize(tests, listeners, environments, config, name)
      @tests = tests
      @config = config
      @thread_pool = ThreadPool.new(my_config[:thread_count] || 1)
      @name = name

      # TODO: initialize logger from config (yml or just ruby code)
      # @logger = Logger.new(STDOUT)
      @logger = Logger.new(File.open("#{MotoApp::DIR}/moto.log", File::WRONLY | File::APPEND | File::CREAT))
      # @logger.level = Logger::WARN

      @result = Result.new(self)

      # TODO: validate envs, maybe no-env should be supported as well?
      environments << :__default if environments.empty?
      @environments = environments

      @listeners = []
      if listeners.empty?
        my_config[:default_listeners].each do |l|
          @listeners << l.new(self)
        end
      else
        listeners.each do |l|
          @listeners << l.new(self)
        end
      end
      @listeners.unshift(@result)
    end

    def my_config
      caller_path = caller.first.to_s.split(/:\d/)[0]
      keys = []
      if caller_path.include? MotoApp::DIR
        caller_path.sub!( "#{MotoApp::DIR}/lib/", '' )
        keys << 'moto_app'
      elsif caller_path.include? Moto::DIR
        caller_path.sub!( "#{Moto::DIR}/lib/", '' )
        keys << 'moto'
      end
      caller_path.sub!('.rb', '')
      keys << caller_path.split('/')
      keys.flatten!
      eval "@config#{keys.map{|k| "[:#{k}]" }.join('')}"
    end

    def run
      @listeners.each { |l| l.start_run }
      @tests.each do |test|
        @thread_pool.schedule do
          tc = ThreadContext.new(self, test)
          tc.run
        end
      end
      @thread_pool.shutdown
      @listeners.each { |l| l.end_run }
    end

  end
end