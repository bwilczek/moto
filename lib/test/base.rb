require_relative 'status'

module Moto
  module Test
    class Base

      attr_reader   :name
      attr_reader   :env
      attr_reader   :params
      attr_accessor :static_path
      attr_accessor :status

      class << self
        attr_accessor :_path
      end

      def self.inherited(k)
        k._path = caller.first.match(/(.+):\d+:in/)[1]
      end

      def path
        self.class._path
      end

      # Initializes test to be executed with specified params and environment
      def init(params_path, params_index, global_index)
        @env = Moto::Lib::Config.environment
        @params = []
        @params_path = params_path
        #TODO Display name
        @name = self.class.to_s.demodulize
        @name += "_#{@params_path.split("/")[-1].chomp('.param')}" if @params_path
        @status = Moto::Test::Status.new
        @status.name = @name
        @status.test_class_name = self.class.name
        @status.display_name = @status.test_class_name.split('::')[2..-2].join('::')
        @status.env = Moto::Lib::Config.environment
      end

      # Setter for :log_path
      def log_path=(param)
        @log_path = param

        # I hate myself for doing this, but I have no other idea for now how to pass log to Listeners that
        # make use of it (for example WebUI)
        @status.log_path = param
      end

      # @return [String] string with the path to the test's log
      def log_path
        @log_path
      end

      # Use this to run test
      # Initializes status, runs test, handles exceptions, finalizes status after run completion
      def run_test
        status.initialize_run

        #TODO Formatting/optimization
        begin
          @params = eval(File.read(@params_path)) if File.exists?(@params_path.to_s)
          @status.params = @params
        rescue Exception => exception
          status.log_exception(exception)
          raise "ERROR: Invalid parameters file: #{@params_path}.\n\tMESSAGE: #{exception.message}"
        ensure
          status.finalize_run
        end

        begin
          run
        rescue Exception => exception
          status.log_exception(exception)
          raise
        ensure
          status.finalize_run
        end

      end

      # Only to be overwritten by final test execution
      # Use :run_test in order to run test
      def run
        # abstract
      end

      def before
        # abstract
      end

      def after
        # abstract
      end

      def skip(msg = nil)
        raise Exceptions::TestSkipped.new(msg.nil? ? 'Test skipped with no reason given.' : "Skipped: #{msg}")
      end

      def fail(msg = nil)
        if msg.nil?
          msg = 'Test forcibly failed with no reason given.'
        else
          msg = "Forced failure: #{msg}"
        end
        raise Exceptions::TestForcedFailure.new msg
      end

      def pass(msg = nil)
        if msg.nil?
          msg = 'Test forcibly passed with no reason given.'
        else
          msg = "Forced passed: #{msg}"
        end
        raise Exceptions::TestForcedPassed.new msg
      end


      # Checks for equality of both arguments
      def assert_equal(a, b)
        assert(a == b, "Arguments should be equal: #{a} != #{b}.")
      end

      # Checks if passed value is equal to True
      def assert_true(value)
        assert(value, 'Logical condition not met, expecting true, given false.')
      end

      # Checks if passed value is equal to False
      def assert_false(value)
        assert(!value, 'Logical condition not met, expecting false, given true.')
      end

      # Checks if result of condition equals to True
      def assert(condition, message)
        if !condition
          line_number = caller.select { |l| l.match(/#{static_path}:\d*:in `run'/) }.first[/\d+/].to_i

          status.log_failure("ASSERTION FAILED in line #{line_number}: #{message}")
          Thread.current['logger'].error(message)
        end
      end

      # Read a constants value from configuration files while taking the execution environment into the account.
      # @param [String] key Key to be searched for.
      # @return [String] Value of the key or nil if not found
      def const(key)
        Moto::Lib::Config.environment_const(key)
      end

    end
  end
end
