require_relative 'run_status'

module Moto
  module Reporting

    # Manages reporting test and run status' to attached listeners
    class TestReporter

      # @param [Array] listeners An array of class names' of listeners to be created, if nil is passed default values will be taken from config[:listeners]
      # @param [Hash] config to be passed to listeners during creation
      # @param [String] custom_run_name Optional, to be passed to listeners during creation
      def initialize(listeners, config, custom_run_name)

        if listeners.nil?
          listeners = config[:moto][:runner][:default_listeners]
        end

        @listeners = []
        @config = config
        @custom_run_name = custom_run_name
        listeners.each { |l| add_listener(l) }
      end

      # Adds a listener to the list.
      # All listeners on the list will have events reported to them.
      # @param [Moto::Listener::Base] listener class to be added
      def add_listener(listener)
        @listeners << listener.new(listener_config(listener), @custom_run_name)
      end

      # @return [Hash] hash containing part of the config meant for a specific listener
      # @param [Moto::Listener::Base] listener class for which config is to be retrieved
      def listener_config(listener)
        listener_symbol = listener.name.demodulize.underscore.to_sym
        @config[:moto][:listeners][listener_symbol]
      end

      # Reports start of the whole run (set of tests) to attached listeners
      def report_start_run
        @run_status = Moto::Reporting::RunStatus.new

        @listeners.each do |l|
          l.start_run
        end
      end

      # Reports end of the whole run (set of tests) to attached listeners
      def report_end_run
        @listeners.each do |l|
          l.end_run(@run_status)
        end
      end

      # Reports star of a test to all attached listeners
      # @param [Moto::Test::Status] test_status of test which's start is to be reported on
      def report_start_test(test_status)
        @listeners.each do |l|
          l.start_test(test_status)
        end
      end

      # Reports end of a test to all attached listeners
      # @param [Moto::Test::Status] test_status of test which's end is to be reported on
      def report_end_test(test_status)
        @run_status.add_test_status(test_status)

        @listeners.each do |l|
          l.end_test(test_status)
        end
      end

    end
  end
end
