require 'rest-client'
require 'uri'

module Moto
  module Reporting
    module Listeners
      class Webui < Base

        REST_MAX_TRIES = 1
        REST_TIMEOUT = 15

        def initialize(run_params)
          super

          if run_params[:mwui_path].nil?
            raise 'ERROR: Please specify directory path (--mwui-path /EXAMPLE/PATH) when using MotoWebUI as one of the listeners.'
          else
            @mwui_path = run_params[:mwui_path]
          end

          if run_params[:mwui_assignee_id]
            @assignee = run_params[:mwui_assignee_id]
          else
            @assignee = config[:default_assignee]
          end

          @tests = {}
          @url = URI.escape("#{config[:url]}/api/motoresults")
          @send_log_on_pass = config[:send_log_on_pass]
        end

        def start_run
        end

        def start_test(test_status, test_metadata)

          # Prepare data for new Test
          test_data = {
              name: test_status.display_name,
              start_time: Time.now
          }

          if !test_metadata.ticket_urls.empty?
            test_data[:ticket_urls] = test_metadata.ticket_urls.join(',')
          end

          if !test_metadata.tags.empty?
            test_data[:tags] = test_metadata.tags.join(',')
          end

          if !test_metadata.description.empty?
            test_data[:description] = test_metadata.description
          end

          # Store Test in a hash with its name as key so later it can be accessed
          @tests[test_data[:name]] = test_data
        end


        def end_test(test_status)
          test_data = {
              duration: (Time.now.to_f - test_status.time_start).to_i,
              error_message: test_status.results.last.code == Moto::Test::Result::ERROR ? test_status.results.last.message : nil,
              fail_message: test_failures(test_status),
              result_id: webui_result_id(test_status.results.last.code)
          }

          @tests[test_status.display_name].merge!(test_data)

          # Add Log to already existing Test
          # if (test_status.results.last.code == Moto::Test::Result::PASSED && @send_log_on_pass) || test_status.results.last.code != Moto::Test::Result::PASSED
          #
          #   url_log = "#{url_test}/logs"
          #   log_data = { text: File.read(test_status.log_path) }.to_json
          #
          #   response = try {
          #     RestClient::Request.execute(method: :post,
          #                                 url: URI.escape(url_log),
          #                                 payload: log_data,
          #                                 timeout: REST_TIMEOUT,
          #                                 headers: {content_type: :json, accept: :json})
          #   }
          #   response
          # end

        end


        def end_run(run_status)
          # Ultimately converts Hash to Array, which is going to be way more useful at this point
          # Assignment is done to the same variable, instead of new one, in order to conserve memory since effectively
          # we're just duplicating the same data
          @tests = @tests.values

          while !@tests.empty?
            partial_run_data = {
                path: @mwui_path,
                tester_id: @assignee,
                tests: @tests.shift(config[:results_in_request])
            }.to_json

            response = try {
              RestClient::Request.execute(method: :post,
                                          url: @url,
                                          payload: partial_run_data,
                                          timeout: REST_TIMEOUT,
                                          headers: {content_type: :json, accept: :json})
            }

            response = JSON.parse(response, symbolize_names: true)
            response
          end

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