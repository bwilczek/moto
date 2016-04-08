require_relative '../reporting/test_reporter'
require_relative './test_provider'

module Moto
  module Runner
    class TestRunner

      attr_reader :logger
      attr_reader :config
      attr_reader :test_reporter

      def initialize(test_paths_absolute, environments, config, test_reporter)
        @test_paths_absolute = test_paths_absolute
        @config = config
        @test_reporter = test_reporter

        # TODO: initialize logger from config (yml or just ruby code)
        @logger = Logger.new(File.open("#{MotoApp::DIR}/moto.log", File::WRONLY | File::APPEND | File::CREAT))

        @environments = environments.empty? ? environments << :__default : environments
      end

      # TODO: Remake
      # @return [Hash] hash with config
      def my_config
        caller_path = caller.first.to_s.split(/:\d/)[0]
        keys = []
        if caller_path.include? MotoApp::DIR
          caller_path.sub!("#{MotoApp::DIR}/lib/", '')
          keys << 'moto_app'
        elsif caller_path.include? Moto::DIR
          caller_path.sub!("#{Moto::DIR}/lib/", '')
          keys << 'moto'
        end
        caller_path.sub!('.rb', '')
        keys << caller_path.split('/')
        keys.flatten!
        eval "@config#{keys.map { |k| "[:#{k}]" }.join('')}"
      end

      def run
        test_provider = TestProvider.new(@test_paths_absolute, @environments)
        threads_max = @config[:moto][:test_runner][:thread_count] || 1

        # remove log/screenshot files from previous execution
        @test_paths_absolute.each do |test_path|
          Dir.glob("#{File.dirname(test_path)}/*.{log,png}").each { |f| File.delete(f) }
        end

        @test_reporter.report_start_run

        (1..threads_max).each do |index|
          Thread.new do
            Thread.current[:id] = index
            loop do
              tc = ThreadContext.new(@config, test_provider.get_test, @test_reporter)
              tc.run
            end
          end
        end

        loop do
          break if test_provider.num_waiting == threads_max
          sleep 1
        end

        @test_reporter.report_end_run
      end

    end
  end
end