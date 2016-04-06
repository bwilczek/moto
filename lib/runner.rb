require_relative './reporting/test_reporter'

module Moto
  class Runner

    attr_reader :logger
    attr_reader :environments
    attr_reader :assert
    attr_reader :config
    attr_reader :name
    attr_reader :test_reporter

    def initialize(tests, environments, config, test_reporter)
      @tests = tests
      @config = config
      @thread_pool = ThreadPool.new(my_config[:thread_count] || 1)
      @test_reporter = test_reporter

      # TODO: initialize logger from config (yml or just ruby code)
      # @logger = Logger.new(STDOUT)
      @logger = Logger.new(File.open("#{MotoApp::DIR}/moto.log", File::WRONLY | File::APPEND | File::CREAT))
      # @logger.level = Logger::WARN

      # TODO: validate envs, maybe no-env should be supported as well?
      environments << :__default if environments.empty?
      @environments = environments
    end

    # TODO: Remake
    # @return [Hash] hash with config
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
      @test_reporter.report_start_run

      @tests.each do |test|
        @thread_pool.schedule do
          tc = ThreadContext.new(self, test, @test_reporter)
          tc.run
        end
      end

      @thread_pool.shutdown
      @test_reporter.report_end_run
    end

  end
end