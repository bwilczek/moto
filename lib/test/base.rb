require_relative 'test_status'

module Moto
  module Test
    class Base

      include Moto::Assert
      include Moto::ForwardContextMethods

      attr_reader   :name
      attr_writer   :context
      attr_reader   :env
      attr_reader   :params
      attr_accessor :static_path
      attr_accessor :evaled
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

      def initialize
        @status = Moto::Test::Status.new
      end

      def init(env, params, params_index)
        @env = env
        @params = params
        @name = generate_name(params_index)

        @status.name = @name
        @status.test_class_name = self.class.name
      end

      # Generates name of the test based on its properties:
      #  - number/name of currently executed configuration run
      #  - env
      def generate_name(params_index)
        if @env == :__default
          return "#{self.class.to_s}" if @params.empty?
          return "#{self.class.to_s}/#{@params['__name']}" if @params.key?('__name')
          return "#{self.class.to_s}/params_#{params_index}" unless @params.key?('__name')
        else
          return "#{self.class.to_s}/#{@env}" if @params.empty?
          return "#{self.class.to_s}/#{@env}/#{@params['__name']}" if @params.key?('__name')
          return "#{self.class.to_s}/#{@env}/params_#{params_index}" unless @params.key?('__name')
        end
        self.class.to_s
      end
      private :generate_name

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

      def dir
        return File.dirname(@static_path) unless @static_path.nil?
        File.dirname(self.path)
      end

      def filename
        return File.basename(@static_path, ".*") unless @static_path.nil?
        File.basename(path, ".*")
      end

      # Use this to run test
      # This is the place to add any code that has to be executed in test's scope before its run
      def run_with_preparations
        status.time_start = Time.now.to_f
        run
      end

      # Only to be overwritten by final test execution
      # Use :run_with_preparations in order to run test
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
        if msg.nil?
          msg = 'Test skipped with no reason given.'
        else
          msg = "Skip reason: #{msg}"
        end
        raise Exceptions::TestSkipped.new msg
      end

      def fail(msg = nil)
        if msg.nil?
          msg = 'Test forcibly failed with no reason given.'
        else
          msg = "Forced failure, reason: #{msg}"
        end
        raise Exceptions::TestForcedFailure.new msg
      end

      def pass(msg = nil)
        if msg.nil?
          msg = 'Test forcibly passed with no reason given.'
        else
          msg = "Forced passed, reason: #{msg}"
        end
        raise Exceptions::TestForcedPassed.new msg
      end

    end
  end
end
