module Moto
  module Reporting

    # Manages reporting test and run status' to attached listeners
    class TestReporter

      # @return [Hash] Hash of objects which represents status of tests executed in current run
      #   keys:  [String] Name property of a [Moto::Test]
      #   value: [Moto::Reporting::TestStatus]
      def test_statuses
        @test_statuses
      end

      def initialize(listeners)
        @listeners = []
        listeners.each { |l| add_listener(l) }
      end

      # Adds a listener to the list.
      # All listeners on the list will have events reported to them.
      # @param [Moto::Listener] listener to be added
      def add_listener(listener)
        @listeners << listener.new
      end

      def report_start_run
        @test_statuses = []

        # TODO: report @run_status
      end

      def report_end_run
        # TODO: report @run_status
      end

      # Reports star of a test to all attached listeners
      # @param [Moto::Test::Base] test_status of test which's start is to be reported on
      def report_start_test(test_status)
        @listeners.each do |l|
          l.start_test(test_status)
        end
      end

      # Reports end of a test to all attached listeners
      # @param [Moto::Test::Status] test_status of test which's end is to be reported on
      def report_end_test(test_status)
        @listeners.each do |l|
          l.end_test(test_status)
        end
      end

    end
  end
end
