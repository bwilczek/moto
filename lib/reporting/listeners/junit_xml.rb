require 'nokogiri'

module Moto
  module Reporting
    module Listeners
      class JunitXml < Base

        def end_run(run_status)
          path = @runner.my_config[:output_file]

          builder = Nokogiri::XML::Builder.new { |xml|
            xml.testsuite(
                  errors: @runner.result.summary[:cnt_error],
                  failures: @runner.result.summary[:cnt_failure],
                  name: "Moto run",
                  tests: @runner.result.summary[:cnt_all],
                  time: @runner.result.summary[:duration],
                  timestamp: Time.at(@runner.result.summary[:started_at])) do
              @runner.result.all.each do |test_name, data|
                xml.testcase(name: test_name, time: data[:duration], classname: data[:class].name, moto_result: data[:result]) do
                  if !data[:error].nil?
                    xml.error(message: data[:error].message)
                  elsif data[:failures].count > 0
                    data[:failures].each do |f|
                      xml.failure(message: f)
                    end
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