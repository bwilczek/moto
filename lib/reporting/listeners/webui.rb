require 'rest-client'
require 'sys/uname'
require 'uri'

module Moto
  module Reporting
    module Listeners
      class Webui < Base

        REST_MAX_TRIES = 1
        REST_TIMEOUT = 15

        def initialize(run_params)
          super

          if run_params[:suite_name].nil?
            raise 'ERROR: Please specify suite name (-s SUITE_NAME) when using MotoWebUI as one of the listeners.'
          end

          if run_params[:assignee]
            @assignee = run_params[:assignee]
          else
            @assignee = config[:default_assignee]
          end

          @tests = {}
          @url = "#{config[:url]}/api"
          @send_log_on_pass = config[:send_log_on_pass]
        end


        def start_run

          # Create Suite, if it did exist already nothing new will be created and existing data will be sent in the response
          url_suites = "#{@url}/suites"
          suite_data = {name: run_params[:suite_name]}.to_json

          response = try {
            RestClient::Request.execute(method: :post,
                                                 url: URI.escape(url_suites),
                                                 payload: suite_data,
                                                 timeout: REST_TIMEOUT,
                                                 headers: {content_type: :json, accept: :json})
          }
          suite = JSON.parse(response, symbolize_names: true)

          # Store ID of current Suite
          @suite_id = suite[:id]

          # Prepare data for new TestRun
          url_runs = "#{@url}/suites/#{@suite_id}/runs"
          run_data = {
              name: run_params[:run_name],
              start_time: Time.now
          }

          if @assignee
            run_data[:tester_id] = @assignee
          end

          run_data = run_data.to_json

          # Create new TestRun based on prepared data
          response = try {
            RestClient::Request.execute(method: :post,
                                                 url: URI.escape(url_runs),
                                                 payload: run_data,
                                                 timeout: REST_TIMEOUT,
                                                 headers: {content_type: :json, accept: :json})
          }

          @run = JSON.parse(response, symbolize_names: true)
        end


        def end_run(run_status)

          url_run = "#{@url}/suites/#{@suite_id}/runs/#{@run[:id]}"
          run_data = {
              duration: (Time.now.to_f - run_status.time_start).to_i
          }.to_json

          response = try {
            RestClient::Request.execute(method: :put,
                                        url: URI.escape(url_run),
                                        payload: run_data,
                                        timeout: REST_TIMEOUT,
                                        headers: {content_type: :json, accept: :json})
          }
          @run = JSON.parse(response, symbolize_names: true)
        end


        def start_test(test_status, test_metadata)

          # Prepare data for new Test
          url_tests = "#{@url}/suites/#{@suite_id}/runs/#{@run[:id]}/tests"
          test_data = {
              name: test_status.display_name, #test_status.test_class_name
              run_id: @run[:id],
              start_time: Time.now
          }

          if test_metadata.ticket_url
            test_data[:ticket_url] = test_metadata.ticket_url
          end

          if test_metadata.tags
            test_data[:tags] = test_metadata.tags.join(',')
          end

          test_data = test_data.to_json

          # Create new Test based on prepared data
          response = try {
            RestClient::Request.execute(method: :post,
                                                 url: URI.escape(url_tests),
                                                 payload: test_data,
                                                 timeout: REST_TIMEOUT,
                                                 headers: {content_type: :json, accept: :json})
          }

          test = JSON.parse(response, symbolize_names: true)

          # Store Test in a hash with its name as key so later it can be accessed and server side ID can be retrieved
          @tests[test[:name]] = test
        end


        def end_test(test_status)

          url_test = "#{@url}/suites/#{@suite_id}/runs/#{@run[:id]}/tests/#{@tests[test_status.display_name][:id]}"
          test_data = {
              log: (test_status.results.last.code == Moto::Test::Result::PASSED && !@send_log_on_pass) ? nil : File.read(test_status.log_path),
              duration: (Time.now.to_f - test_status.time_start).to_i,
              error_message: test_status.results.last.code == Moto::Test::Result::ERROR ? nil : test_status.results.last.message,
              fail_message: test_failures(test_status),
              result_id: webui_result_id(test_status.results.last.code),
          }.to_json

          test_data = test_data
          # Create new Test based on prepared data
          response = try {
            RestClient::Request.execute(method: :put,
                                                 url: URI.escape(url_test),
                                                 payload: test_data,
                                                 timeout: REST_TIMEOUT,
                                                 headers: {content_type: :json, accept: :json})
          }

          test = JSON.parse(response, symbolize_names: true)

          @tests[test_status.name] = test
        end

        # @return [String] string with messages of all failures in a test
        def test_failures(test_status)
          if test_status.results.last.failures.empty?
            return nil
          end

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

        def webui_result_id(code)
          case code
            when Moto::Test::Result::RUNNING
              1
            when Moto::Test::Result::PASSED
              2
            when Moto::Test::Result::FAILURE
              3
            when Moto::Test::Result::ERROR
              4
            when Moto::Test::Result::SKIPPED
              5
          end
        end
        private :webui_result_id

      end
    end
  end
end