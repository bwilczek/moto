module Moto
  class Runner
    
    attr_reader :result
    attr_reader :listeners
    attr_reader :logger
    attr_reader :environments
    attr_reader :assert
    attr_reader :config
    
    def initialize(tests, listeners, environments, config)
      @tests = tests
      @config = config
      @threads = []
      
      # TODO: initialize logger from config (yml or just ruby code)
      # @logger = Logger.new(STDOUT)
      @logger = Logger.new(File.open("#{APP_DIR}/moto.log", File::WRONLY | File::APPEND | File::CREAT))
      # @logger.level = Logger::WARN
      
      @result = Result.new(self)
      
      # TODO: validate envs, maybe no-env should be supported as well?
      @environments = environments
      
      @listeners = []
      listeners.each do |l|
        @listeners << l.new(self)
      end
      @listeners.unshift(@result)
    end
    
    def run
      @listeners.each { |l| l.start_run }
      test_slices = @tests.each_slice((@tests.size.to_f/@config[:thread_count]).ceil).to_a
      (0...test_slices.count).each do |i|
        @threads << Thread.new do
          tc = ThreadContext.new(self, test_slices[i])
          tc.run
        end
      end
      @threads.each{ |t| t.join }
      @listeners.each { |l| l.end_run }
    end
    
  end
end