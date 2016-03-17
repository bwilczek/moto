module Moto
  module Reporting
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
      # @param [Moto::Test] test which's start has to be reported on
      def report_start_test(test)
        test_status = get_test_status(test)

        @listeners.each do |l|
          l.start_test(test_status)
        end
      end

      # Reports end of a test to all attached listeners
      # @param [Moto::Test] test which's end has to be reported on
      def report_end_test(test)
        test_status = get_test_status(test)

        @listeners.each do |l|
          l.end_test(test_status)
        end
      end

      # @param [Moto::Test] test for which status has to be retrieved
      # @return [Moto::Reporting::TestStatus] status of the specified test
      def get_test_status(test)
        test_status = test_statuses.key(test.name)

        if test_status.nil?
          test_status = Moto::Reporting::TestStatus.new
        end

        test_status
      end

      # After a single run of a test has been completed it's neccessary to update status information
      # with newest passes, failures, errors etc.
      def evaluate_status_after_run(test, run_exception)
        get_test_status(test).evaluate_status_after_run(run_exception)
      end

    end
  end
end
