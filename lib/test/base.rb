require_relative 'status'
require 'logger'

module Moto
  module Test
    class Base

      attr_reader   :name
      attr_reader   :params
      attr_accessor :static_path
      attr_accessor :status

      # Contains information specified by user in Test headers, marked with appropriate tags
      # @return [Moto::Test::Metadata]
      attr_accessor :metadata

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
      def init(params_path)
        @params = []
        @params_path = params_path

        @name = self.class.to_s.demodulize
        @name += "_#{@params_path.split('/')[-1].chomp('.param')}" if @params_path

        @status = Moto::Test::Status.new
        @status.name = @name
        @status.test_class_name = self.class.name
        @status.display_name = @status.test_class_name.split('::')[2..-2].join(' > ')
        @status.display_name += "_#{@params_path.split('/')[-1].chomp('.param')}" if @params_path
        @status.display_name += "(#{metadata.test_repeat})" if metadata.test_repeat > 1
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

      # Checks for equality of both values using operator ==
      #
      # @param [Object] value1
      # @param [Object] value2
      # @param [String] failure_message Will be logged/displayed when assertion fails.
      #   Substrings '$1' and '$2' (without quotes) found in string will be replaced,
      #   respectively, with value1.to_s and value2.to_s
      def assert_equal(value1, value2, failure_message = "Arguments should be equal: $1 != $2")
        if value1 != value2
          report_failed_assertion(failure_message.gsub('$1', value1.to_s).gsub('$2', value2.to_s))
        end
      end

      # Checks if passed value is equal to True
      #
      # @param [Object] value
      # @param [String] failure_message Will be logged/displayed when assertion fails.
      #   Substring '$1' (without quotes) found in string will be replaced with value.to_s
      def assert_true(value, failure_message = "Logical condition not met, expecting true, given $1")
        if !value
          report_failed_assertion(failure_message.gsub('$1', value.to_s))
        end
      end
      alias_method :assert, :assert_true

      # Checks if passed value is equal to False
      #
      # @param [Object] value
      # @param [String] failure_message Will be logged/displayed when assertion fails.
      #   Substring '$1' (without quotes) found in string will be replaced with value.to_s
      def assert_false(value, failure_message = "Logical condition not met, expecting false, given $1")
        if value
          report_failed_assertion(failure_message.gsub('$1', value.to_s))
        end
      end

      def report_failed_assertion(failure_message)
        line_number = caller.select { |l| l.match(/#{static_path}:\d*:in `run'/) }.first[/\d+/].to_i
        status.log_failure("ASSERTION FAILED in line #{line_number}: #{failure_message}")
        logger.error(failure_message)
      end

      # @return [Hash] Configuration for selected environment + current thread combination
      def env
        Moto::Lib::Config.environment_config
      end

      # @return [Logger]
      def logger
        Thread.current['logger']
      end

    end
  end
end
