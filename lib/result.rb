module Moto
  class Result
    
    PENDING = :pending # -2
    RUNNING = :running # -1
    PASSED = :passed # 0
    FAILURE = :failure # 1
    ERROR = :error # 2

    attr_reader :summary

    def [](key)
      @results[key]
    end
    
    def initialize(runner)
      @runner = runner
      @results = {}
      @summary = {}
    end
    
    def start_run
      # start timer
      @summary[:started_at] = Time.now.to_f
    end
    
    def end_run
      # info about duration and overall execution result
      @summary[:finished_at] = Time.now.to_f
      @summary[:duration] = @summary[:finished_at] - @summary[:started_at]
      @summary[:result] = PASSED
      @summary[:result] = FAILURE unless @results.values.select{ |v| v[:failures].count > 0 }.empty?
      @summary[:result] = ERROR unless @results.values.select{ |v| !v[:error].nil? }.empty?
      @summary[:cnt_all] = @results.count
      @summary[:cnt_passed] = @results.values.select{ |v| v[:result] == PASSED }.count
      @summary[:cnt_failure] = @results.values.select{ |v| v[:result] == FAILURE }.count
      @summary[:cnt_error] = @results.values.select{ |v| v[:result] == ERROR }.count
      @summary[:tests_passed] = @results.select{ |k,v| v[:result] == PASSED }
      @summary[:tests_failure] = @results.select{ |k,v| v[:result] == FAILURE }
      @summary[:tests_error] = @results.select{ |k,v| v[:result] == ERROR }
    end
    
    def start_test(test)
      @results[test.name] = { class: test.class, result: RUNNING, env: test.env, params: test.params, name: test.name, error: nil, failures: [], started_at: Time.now.to_f } 
    end

    def end_test(test)
      # calculate result basing on errors/failures
      test.result = PASSED
      test.result = FAILURE unless @results[test.name][:failures].empty?
      test.result = ERROR unless @results[test.name][:error].nil?
      @results[test.name][:finished_at] = Time.now.to_f
      @results[test.name][:duration] = @results[test.name][:finished_at] - @results[test.name][:started_at]
      @results[test.name][:result] = test.result
    end

    def add_failure(test, msg)
      @results[test.name][:failures] << msg
    end
    
    def add_error(test, e)
      @results[test.name][:error] = e
    end
    
  end
end