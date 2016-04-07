require_relative './reporting/test_reporter'
require_relative './tests_queue'
module Moto
  class Runner

    attr_reader :logger
    attr_reader :environments
    attr_reader :config
    attr_reader :test_reporter

    def initialize(test_paths_absolute, environments, config, test_reporter)
      @test_paths_absolute = test_paths_absolute
      @config = config
      @test_reporter = test_reporter

      # TODO: initialize logger from config (yml or just ruby code)
      # @logger = Logger.new(STDOUT)
      @logger = Logger.new(File.open("#{MotoApp::DIR}/moto.log", File::WRONLY | File::APPEND | File::CREAT))
      # @logger.level = Logger::WARN

      # TODO: validate envs, maybe no-env should be supported as well?
      environments << :__default if environments.empty?
      @environments = environments
    end

    def run
      tests_queue = TestsQueue.new(@test_paths_absolute)
      thread_count = @config[:moto][:runner][:thread_count] || 1

      @test_reporter.report_start_run

      (1..thread_count).each do |index|
        Thread.new do
          Thread.current[:id] = index
          loop do
            tc = ThreadContext.new(self, tests_queue.get_test, @test_reporter)
            tc.run
          end
        end
      end

      loop do
        break if tests_queue.num_waiting == threads_max
        sleep 1
      end

      @test_reporter.report_end_run
    end

  end
end