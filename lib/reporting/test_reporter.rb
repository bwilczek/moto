require_relative 'run_status'

module Moto
  module Reporting

    # Manages reporting test and run status' to attached listeners
    class TestReporter

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

      # Reports start of the whole run (set of tests) to attached listeners
      def report_start_run
        @run_status = Moto::Reporting::RunStatus.new

        @listeners.each do |l|
          l.start_run
        end
      end

      # Reports end of the whole run (set of tests) to attached listeners
      def report_end_run

        # @summary[:finished_at] = Time.now.to_f
        # @summary[:duration] = @summary[:finished_at] - @summary[:started_at]
        # @summary[:result] = PASSED
        # @summary[:result] = FAILURE unless @results.values.select{ |v| v[:failures].count > 0 }.empty?
        # @summary[:result] = ERROR unless @results.values.select{ |v| v[:result] == ERROR }.empty?
        # @summary[:cnt_all] = @results.count
        # @summary[:tests_passed] = @results.select{ |k,v| v[:result] == PASSED }
        # @summary[:tests_failure] = @results.select{ |k,v| v[:result] == FAILURE }
        # @summary[:tests_error] = @results.select{ |k,v| v[:result] == ERROR }
        # @summary[:tests_skipped] = @results.select{ |k,v| v[:result] == SKIPPED }
        # @summary[:cnt_passed] = @summary[:tests_passed].count
        # @summary[:cnt_failure] = @summary[:tests_failure].count
        # @summary[:cnt_error] = @summary[:tests_error].count
        # @summary[:cnt_skipped] = @summary[:tests_skipped].count

        @listeners.each do |l|
          l.end_run(@run_status)
        end
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
        @run_status.add_test_status(test_status)

        @listeners.each do |l|
          l.end_test(test_status)
        end
      end

    end
  end
end
