require 'rest-client'
require 'sys/uname'

module Moto
  module Reporting
    module Listeners
      class Webui < Base

        def start_run
          # POST http://sandbox.dev:3000/api/runs/create
          @url = config[:url]
          data = {
            name:         custom_run_name,
            result:       :running,
            cnt_all:      nil,
            cnt_passed:   nil,
            cnt_failure:  nil,
            cnt_error:    nil,
            cnt_skipped:  nil,
            user:         Sys::Uname.sysname.downcase.include?('windows') ? ENV['USERNAME'] : ENV['LOGNAME'],
            host:         Sys::Uname.nodename,
            pid:          Process.pid
          }

          @run = JSON.parse( RestClient.post( "#{@url}/api/runs", data.to_json, :content_type => :json, :accept => :json ) )
          @tests = {}
        end

        def end_run(run_status)
          # PUT http://sandbox.dev:3000/api/runs/1
          data = {
            result:       run_status.result,
            cnt_all:      run_status.tests_all.length,
            cnt_passed:   run_status.tests_passed.length,
            cnt_failure:  run_status.tests_failed.length,
            cnt_error:    run_status.tests_error.length,
            cnt_skipped:  run_status.tests_skipped.length,
            duration:     run_status.duration
          }

          @run = JSON.parse( RestClient.put( "#{@url}/api/runs/#{@run['id']}", data.to_json, :content_type => :json, :accept => :json ) )
        end

        def start_test(test_status)
          # POST http://sandbox.dev:3000/api/tests/create
          data = {
            name:       test_status.name,
            class_name: test_status.test_class_name,
            log:        nil,
            run_id:     @run['id'],
            env:        test_status.env,
            parameters: test_status.params.to_s,
            result:     :running,
            error:      nil,
            failures:   nil
          }

          @tests[test_status.name] = JSON.parse( RestClient.post( "#{@url}/api/tests", data.to_json, :content_type => :json, :accept => :json ) )
        end

        def end_test(test_status)
          data = {
            log:      File.read(test_status.log_path),
            result:   test_status.results.last.code,
            error:    test_status.results.last.code == Moto::Test::Result::ERROR ? nil : test_status.results.last.message,
            failures: test_failures(test_status),
            duration: test_status.duration
          }

          @tests[test_status.name] = JSON.parse( RestClient.put( "#{@url}/api/tests/#{@tests[test_status.name]['id']}", data.to_json, :content_type => :json, :accept => :json ) )
        end

        # @return [String] string with messages of all failures in a test
        def test_failures(test_status)
          test_status.results.last.failures.join("\n\t")
        end

      end
    end
  end
end