require 'nokogiri'

module Moto
  module Reporting
    module Listeners
      class JunitXml < Base

        def end_run(run_status)
          path = config[:output_file]

          run_status_hash = {
              errors:     run_status.tests_error.length,
              failures:   run_status.tests_error.length,
              name:       custom_run_name,
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
                  if test_status.final_result.code == Moto::Test::Result::ERROR
                    xml.error(message: test_status.final_result.message)
                  elsif test_status.final_result.code == Moto::Test::Result::FAILURE
                    xml.failure(message: test_status.final_result.message)
                  end
                end
              end
            end
          }

          File.open(path, 'w') {|f| f.write(builder.to_xml) }
        end

        # @return [Array] array with [Moto::Test::Result] of all failures in a test
        def test_failures(test_status)
          test_status.results.select { |result| result.code == Moto::Test::Result::FAILURE }
        end
      end
    end
  end
end