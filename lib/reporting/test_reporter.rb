require_relative 'run_status'

module Moto
  module Reporting

    # Manages reporting test and run status' to attached listeners
    class TestReporter

      attr_reader :run_status

      # @param [Array] listeners An array of strings, which represent qualified names of classes (listeners) that will be instantiated.
      #                empty array is passed then :default_listeners will be taken from config
      def initialize(listeners, run_params)

        if listeners.empty?
          config[:default_listeners].each do |listener_class_name|
            listeners << listener_class_name
          end
        else
          listeners.each_with_index do |listener_class_name, index|
            listeners[index] = ('Moto::Reporting::Listeners::' + listener_class_name.camelize).constantize
          end
        end

        @listeners = []
        @run_params = run_params
        listeners.each { |l| add_listener(l) }
      end

      # Adds a listener to the list.
      # All listeners on the list will have events reported to them.
      # @param [Moto::Listener::Base] listener class to be added
      def add_listener(listener)
        @listeners << listener.new(@run_params)
      end

      # Reports start of the whole run (set of tests) to attached listeners
      def report_start_run
        @run_status = Moto::Reporting::RunStatus.new
        @run_status.initialize_run

        @listeners.each do |l|
          begin
            l.start_run
          rescue Exception => e
            puts "Listener #{l.class.name} on Start run: #{e.to_s}"
          end
        end
      end

      # Reports end of the whole run (set of tests) to attached listeners
      def report_end_run
        @run_status.finalize_run

        @listeners.each do |l|
          begin
            l.end_run(@run_status)
          rescue Exception => e
            puts "Listener #{l.class.name} on End run: #{e.to_s}"
          end
        end
      end

      # Reports start of a test to all attached listeners
      # @param [Moto::Test::Status] test_status of test which's start is to be reported on
      # @param [Moto::Test::Metadata] test_metadata of test which's start is to be reported on
      def report_start_test(test_status, test_metadata)
        @listeners.each do |l|
          begin
            l.start_test(test_status, test_metadata)
          rescue Exception => e
            puts "Listener #{l.class.name} on Start test: #{e.to_s}"
          end
        end
      end

      # Reports end of a test to all attached listeners
      # @param [Moto::Test::Status] test_status of test which's end is to be reported on
      def report_end_test(test_status)
        @run_status.add_test_status(test_status)

        @listeners.each do |l|
          begin
            l.end_test(test_status)
          rescue Exception => e
            puts "Listener #{l.class.name} on End test: #{e.to_s}"
          end
        end
      end

      # @return [Hash] Hash with config for TestReporter
      def config
        Moto::Lib::Config.moto[:test_reporter]
      end
      private :config

    end
  end
end
