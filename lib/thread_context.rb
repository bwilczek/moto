require 'erb'

module Moto
  class ThreadContext

    # all resources specific for single thread will be initialized here. E.g. browser session
    attr_reader :runner
    attr_reader :logger
    # attr_reader :log_path
    attr_reader :current_test

    def initialize(runner, test, test_reporter)
      @runner = runner
      @test = test
      @clients = {}
      @test.context = self
      @test_reporter = test_reporter

      #TODO temporary fix
      Thread.current['context']= self

      @config = {}
      Dir.glob("config/*.yml").each do |f|
        @config.deep_merge! YAML.load_file(f)
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
               "@config#{key.split('.').map { |a| "['#{a}']" }.join('')}"
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
      # remove log/screenshot files from previous execution
      Dir.glob("#{@test.dir}/*.{log,png}").each { |f| File.delete f }
      max_attempts = @runner.my_config[:max_attempts] || 1
      sleep_time = @runner.my_config[:sleep_before_attempt] || 0
      @runner.environments.each do |env|
        params_all = [{}]

        # YAML config files
        #params_path = "#{@test.dir}/#{@test.filename}_params.yml"
        #params_all = YAML.load(ERB.new(File.read(params_path)).result) if File.exists?(params_path)

        # RB Config files
        params_path = "#{@test.dir}/#{@test.filename}"
        params_all = eval(File.read(params_path)) if File.exists?(params_path)

        params_all.each_with_index do |params, params_index|

          # Filtering out param sets that are specific to certain envs
          unless params['__env'].nil?
            allowed_envs = params['__env'].is_a?(String) ? [params['__env']] : params['__env']
            next unless allowed_envs.include? env
          end

          (1..max_attempts).each do |attempt|
            @test.init(env, params, params_index)
            # TODO: log path might be specified (to some extent) by the configuration
            @test.log_path = "#{@test.dir}/#{@test.name.gsub(/\s+/, '_').gsub(':', '_').gsub('::', '_').gsub('/', '_')}.log"
            @logger = Logger.new(File.open(@test.log_path, File::WRONLY | File::TRUNC | File::CREAT))
            @logger.level = @runner.my_config[:log_level] || Logger::DEBUG
            @current_test = @test

            # Reporting: start_test
            if attempt == 1
              @test_reporter.report_start_test(@test.status)
            end

            @clients.each_value { |c| c.start_test(@test) }
            @test.before
            @logger.info "Start: #{@test.name} attempt #{attempt}/#{max_attempts}"

            # Any exceptions caught during the execution of the test in this run will be saved to this variable
            test_attempt_exception = nil

            begin
              @test.run_with_preparations
            rescue Exceptions::TestForcedPassed, Exceptions::TestForcedFailure, Exceptions::TestSkipped => e
              logger.info(e.message)

              test_attempt_exception = e
            rescue Exception => e
              @logger.error("#{e.class.name}: #{e.message}")
              @logger.error(e.backtrace.join("\n"))
              @clients.each_value { |c| c.handle_test_exception(@test, e) }

              test_attempt_exception = e
            ensure
              # TODO: test should auto-evaluate it's status on events
              @test.status.evaluate_status_after_run(test_attempt_exception)
            end

            @test.after
            @clients.each_value { |c| c.end_test(@test) }

            @logger.info("Result: #{@test.status.final_result.code}")
            @logger.close

            # stop re-running test when passable (pass, skip) result has been achieved
            if  @test.status.final_result.code != Moto::Test::Result::FAILURE &&
                @test.status.final_result.code != Moto::Test::Result::ERROR
              break
            end

            # don't go to sleep in the last attempt
            if attempt < max_attempts
              sleep sleep_time
            end

          end # Make another attempt

          # Reporting: end_test
          @test_reporter.report_end_test(@test.status)

        end
      end
      @clients.each_value { |c| c.end_run }
    end

  end
end