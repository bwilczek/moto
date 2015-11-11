require 'rest-client'
require 'sys/uname'

module Moto
  module Listeners
    class Webui < Base

      def start_run
        # POST http://sandbox.dev:3000/api/runs/create
        @url = @runner.my_config[:url]
        data = {
          name:  @runner.name,
          result: Moto::Result::RUNNING,
          cnt_all: nil,
          cnt_passed: nil,
          cnt_failure: nil,
          cnt_error: nil,
          cnt_skipped: nil,
          user: Sys::Uname.sysname.downcase.include?('windows') ? ENV['USERNAME'] : ENV['LOGNAME'],
          host: Sys::Uname.nodename,
          pid: Process.pid
        }
        @run = JSON.parse( RestClient.post( "#{@url}/api/runs", data.to_json, :content_type => :json, :accept => :json ) )
      end
      
      def end_run
        # PUT http://sandbox.dev:3000/api/runs/1
        data = {
          result: @runner.result.summary[:result],
          cnt_all: @runner.result.summary[:cnt_all],
          cnt_passed: @runner.result.summary[:cnt_passed],
          cnt_failure: @runner.result.summary[:cnt_failure],
          cnt_error: @runner.result.summary[:cnt_error],
          cnt_skipped: @runner.result.summary[:cnt_skipped],
          duration: @runner.result.summary[:duration]
        }
        @run = JSON.parse( RestClient.put( "#{@url}/api/runs/#{@run['id']}", data.to_json, :content_type => :json, :accept => :json ) )
      end

      def start_test(test)
        # POST http://sandbox.dev:3000/api/tests/create
        data = {
          name:  test.name,
          class_name: test.class.name,
          log: nil,
          run_id: @run['id'],
          env: test.env,
          parameters: test.params.to_s,
          result: Moto::Result::RUNNING,
          error: nil,
          failures: nil,
        }
        @test = JSON.parse( RestClient.post( "#{@url}/api/tests", data.to_json, :content_type => :json, :accept => :json ) )        
      end

      def end_test(test)
        log = File.read(test.log_path)
        data = {
          log: log,
          result: @runner.result[test.name][:result],
          error: @runner.result[test.name][:error].nil? ? nil : @runner.result[test.name][:error].message,
          failures: @runner.result[test.name][:failures].join("\n\t"),
          duration: @runner.result[test.name][:duration]
        }        
        @test = JSON.parse( RestClient.put( "#{@url}/api/tests/#{@test['id']}", data.to_json, :content_type => :json, :accept => :json ) )
      end

    end
  end
end