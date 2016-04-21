require 'erb'
require 'fileutils'

module Moto
  module Runner
    class ThreadContext

      # all resources specific for single thread will be initialized here. E.g. browser session
      attr_reader :logger
      attr_reader :test
      attr_reader :moto_app_config

      def initialize(config, test, test_reporter)
        @config = config
        @test = test
        @clients = {}
        @test.context = self
        @test_reporter = test_reporter

        # TODO: temporary fix
        Thread.current['context'] = self

        # TODO: temporary fix
        @moto_app_config = {}
        Dir.glob('config/*.yml').each do |f|
          @moto_app_config.deep_merge! YAML.load_file(f)
        end
      end

      def client(name)
        return @clients[name] if @clients.key? name

        name_app = 'MotoApp::Lib::Clients::' + name
        name_moto = 'Moto::Clients::' + name

        c = try_client(name_app, "#{MotoApp::DIR}/")
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
          client_path = a[1..-1].join('/')
          require "#{dir}/#{client_path}"
          client_const = name.constantize
          instance = client_const.new(self)
          instance.init
          instance.start_run
          instance.start_test(@test)
          return instance
        rescue Exception => e
          # puts e
          # puts e.backtrace
          return nil
        end
      end

      def const(key)
        key = key.to_s
        key = "#{@test.env.to_s}.#{key}" if @test.env != :__default
        code = if key.include? '.'
                 "@moto_app_config#{key.split('.').map { |a| "['#{a}']" }.join('')}"
               else
                 "@moto_app_config['#{key}']"
               end
        begin
          v = eval code
          raise if v.nil?
        rescue
          raise "There is no const defined for key: #{key}. Environment: #{ (@test.env == :__default) ? '<none>' : @test.env }"
        end
        v
      end

      def run
        max_attempts = @config[:moto][:thread_context][:max_attempts] || 1
        sleep_time = @config[:moto][:thread_context][:sleep_before_attempt] || 0

        log_directory = File.dirname(@test.log_path)
        if !File.directory?(log_directory)
          FileUtils.mkdir_p(log_directory)
        end

        @logger = Logger.new(File.open(@test.log_path, File::WRONLY | File::TRUNC | File::CREAT))
        @logger.level = @config[:moto][:thread_context][:log_level] || Logger::DEBUG

        # Reporting: start_test
        @test_reporter.report_start_test(@test.status)

        (1..max_attempts).each do |attempt|

          @clients.each_value { |c| c.start_test(@test) }
          @test.before
          @logger.info "Start: #{@test.name} attempt #{attempt}/#{max_attempts}"

          begin
            @test.run_test
          rescue Exceptions::TestForcedPassed, Exceptions::TestForcedFailure, Exceptions::TestSkipped => e
            @logger.info(e.message)
          rescue Exception => e
            @logger.error("#{e.class.name}: #{e.message}")
            @logger.error(e.backtrace.join("\n"))
            @clients.each_value { |c| c.handle_test_exception(@test, e) }
          end

          @test.after
          @clients.each_value { |c| c.end_test(@test) }

          @logger.info("Result: #{@test.status.results.last.code}")

          # test should have another attempt only in case of an error
          # pass, skip and fail statuses end attempts
          if @test.status.results.last.code != Moto::Test::Result::ERROR
            break
          end

          # don't go to sleep in the last attempt
          if attempt < max_attempts
            sleep sleep_time
          end

        end # Make another attempt

        # Close and flush stream to file
        @logger.close

        # Reporting: end_test
        @test_reporter.report_end_test(@test.status)

        @clients.each_value { |c| c.end_run }

      end

    end
  end
end
