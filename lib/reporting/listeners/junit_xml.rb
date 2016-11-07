require 'nokogiri'

module Moto
  module Reporting
    module Listeners
      class JunitXml < Base

        def end_run(run_status)

          path =  Moto::Lib::Config.moto[:test_reporter][:listeners][:junit_xml][:output_file]

          run_status_hash = {
              errors:     run_status.tests_error.length,
              failures:   run_status.tests_failed.length,
              skipped:    run_status.tests_skipped.length,
              name:       run_params[:run_name],
              tests:      run_status.tests_all.length,
              time:       run_status.duration,
              timestamp:  Time.at(run_status.time_start)
          }

          builder = Nokogiri::XML::Builder.new { |xml|
            xml.testsuite(run_status_hash) do
              run_status.tests_all.each do |test_status|

                test_status_hash = {
                    name:        test_status.name,
                    time:        test_status.duration,
                    classname:   test_status.test_class_name,
                    moto_result: test_status.to_s
                }

                xml.testcase(test_status_hash) do
                  if test_status.results.last.code == Moto::Test::Result::ERROR
                    xml.error(message: test_status.results.last.message)
                  elsif test_status.results.last.code == Moto::Test::Result::FAILURE
                    test_status.results.last.failures.each do |failure_message|
                      xml.failure(message: failure_message)
                    end
                  elsif test_status.results.last.code == Moto::Test::Result::SKIPPED
                    xml.skipped
                  end
                end
              end
            end
          }

          File.open(path, 'w') {|f| f.write(builder.to_xml) }
        end

      end
    end
  end
end