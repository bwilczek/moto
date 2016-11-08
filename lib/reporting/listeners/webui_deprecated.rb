require 'rest-client'
require 'sys/uname'

module Moto
  module Reporting
    module Listeners
      class WebuiDeprecated < Base

        REST_MAX_TRIES = 3
        REST_TIMEOUT = 15

        def start_run

          @url = config[:url]
          @send_log_on_pass = config[:send_log_on_pass]

          data = {
              name: run_params[:name],
              result: :running,
              cnt_all: nil,
              cnt_passed: nil,
              cnt_failure: nil,
              cnt_error: nil,
              cnt_skipped: nil,
              user: Sys::Uname.sysname.downcase.include?('windows') ? ENV['USERNAME'] : ENV['LOGNAME'],
              host: Sys::Uname.nodename,
              pid: Process.pid
          }

          result = try {
            RestClient::Request.execute(method: :post, url: "#{@url}/api/runs", payload: data.to_json, timeout: REST_TIMEOUT, headers: {content_type: :json, accept: :json})
          }

          @run = JSON.parse(result)
          @tests = {}
        end

        def end_run(run_status)
          # PUT http://sandbox.dev:3000/api/runs/1
          data = {
              result: run_status.result,
              cnt_all: run_status.tests_all.length,
              cnt_passed: run_status.tests_passed.length,
              cnt_failure: run_status.tests_failed.length,
              cnt_error: run_status.tests_error.length,
              cnt_skipped: run_status.tests_skipped.length,
              duration: run_status.duration
          }

          result = try {
              RestClient::Request.execute(method: :put, url: "#{@url}/api/runs/#{@run['id']}", payload: data.to_json, timeout: REST_TIMEOUT, headers: {content_type: :json, accept: :json})
          }
          @run = JSON.parse(result)
        end

        def start_test(test_status, test_metadata)
          # POST http://sandbox.dev:3000/api/tests/create
          data = {
              name: test_status.name,
              class_name: test_status.test_class_name,
              log: nil,
              run_id: @run['id'],
              env: test_status.env,
              parameters: test_status.params.to_s,
              result: :running,
              error: nil,
              failures: nil
          }

          result = try {
            RestClient::Request.execute(method: :post, url: "#{@url}/api/tests", payload: data.to_json, timeout: REST_TIMEOUT, headers: {content_type: :json, accept: :json})
          }
          @tests[test_status.name] = JSON.parse(result)
        end

        def end_test(test_status)

          # don't send the log if the test has passed and appropriate flag is set to false
          if test_status.results.last.code == Moto::Test::Result::PASSED && !@send_log_on_pass
            full_log = nil
          else
            full_log = File.read(test_status.log_path)
          end

          data = {
              log: full_log,
              result: test_status.results.last.code,
              error: test_status.results.last.code == Moto::Test::Result::ERROR ? nil : test_status.results.last.message,
              failures: test_failures(test_status),
              duration: test_status.duration
          }

          result = try {
            RestClient::Request.execute(method: :put, url: "#{@url}/api/tests/#{@tests[test_status.name]['id']}", payload: data.to_json, timeout: REST_TIMEOUT, headers: {content_type: :json, accept: :json})
          }
          @tests[test_status.name] = JSON.parse(result)
        end

        # @return [String] string with messages of all failures in a test
        def test_failures(test_status)
          test_status.results.last.failures.join("\n\t")
        end

        # Tries to execute, without an error, block of code passed to the function.
        # @param block Block of code to be executed up to MAX_REST_TRIES
        def try(&block)

          tries = REST_MAX_TRIES

          begin
            yield
          rescue
            tries -= 1
            tries > 0 ? retry : raise
          end
        end

        # @return [Hash] Hash with config for WebUI
        def config
          Moto::Lib::Config.moto[:test_reporter][:listeners][:webui]
        end
        private :config

      end
    end
  end
end