require_relative '../reporting/test_reporter'

require_relative '../test/metadata_generator'

require_relative 'generate/test_template_generator'
require_relative 'run/dry_runner'
require_relative 'run/test_runner'
require_relative 'validate/test_validator'


module Moto
  module Modes
    class ModeSelector

      def run(parsed_arguments)
        tests_metadata = prepare_metadata(parsed_arguments)
        test_reporter = prepare_test_reporter(parsed_arguments)

        if Moto::Lib::Config.moto[:test_runner][:dry_run]
          runner = Moto::Modes::Run::DryRunner.new(tests_metadata, test_reporter)
        else
          runner = Moto::Modes::Run::TestRunner.new(tests_metadata, test_reporter, parsed_arguments[:stop_on])
        end

        runner.run
      end

      def generate(parsed_arguments)
        Moto::Modes::Generate::TestTemplateGenerator.run(parsed_arguments)
      end

      def validate(parsed_arguments)
        tests_metadata = prepare_metadata(parsed_arguments)
        test_reporter = prepare_test_reporter(parsed_arguments)

        validation_options = {}
        validation_options[:tags_regex_positive] = parsed_arguments[:validator_regex_positive] if parsed_arguments[:validator_regex_positive]
        validation_options[:tags_regex_negative] = parsed_arguments[:validator_regex_negative] if parsed_arguments[:validator_regex_negative]
        validation_options[:has_tags]            = parsed_arguments.key?(:validate_has_tags)
        validation_options[:has_description]     = parsed_arguments.key?(:validate_has_description)
        validation_options[:tag_whitelist]       = parsed_arguments[:tag_whitelist] if parsed_arguments[:tag_whitelist]

        validator = Moto::Modes::Validate::TestValidator.new(tests_metadata, validation_options, test_reporter)
        validator.run
      end

      def version
        puts Moto::VERSION
      end

      def prepare_metadata(parsed_arguments)
        tests_metadata = Moto::Test::MetadataGenerator.generate(parsed_arguments[:tests],
                                                                 parsed_arguments[:tags],
                                                                 parsed_arguments[:filters])

        # TODO Display criteria used
        if tests_metadata.empty?
          puts 'No tests found for given arguments.'
          Kernel.exit(-1)
        else
          return tests_metadata
        end
      end
      private :prepare_metadata

      def prepare_test_reporter(parsed_arguments)
        run_params = {}
        run_params[:mwui_path] = parsed_arguments[:mwui_path]
        run_params[:mwui_assignee_id] = parsed_arguments[:mwui_assignee_id]

        Moto::Reporting::TestReporter.new(parsed_arguments[:listeners], run_params)
      end
      private :prepare_test_reporter

    end
  end
end