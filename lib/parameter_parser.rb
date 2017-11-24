begin
  require 'bundler/setup'
  Bundler.require
rescue
  nil
end

require 'optparse'
require 'logger'
require_relative 'config'
require_relative 'modes/mode_selector'

module Moto
  class ParameterParser

    def self.parse_user_input(argv)
      begin

        mode_selector = Moto::Modes::ModeSelector.new

        self.prepare_config(argv)

        # TODO: IMPORTANT ISSUE
        # xxx_parse functions should not return parsed arguments and pass them to functions
        # but instead all should inject proper values into Moto::Lib::Config.moto[:xxx][:yyy]
        # on which all further components should relay

        if argv[0] == '--version'
          mode_selector.version
        elsif argv[0] == 'run' && argv.length > 1
          mode_selector.run(run_parse(argv))
        elsif argv[0] == 'generate' && argv.length > 1
          mode_selector.generate(generate_parse(argv))
        elsif argv[0] == 'validate' && argv.length > 1
          mode_selector.validate(validate_parse(argv))
        else
          show_help
        end

      rescue SystemExit => e
        Kernel.exit(e.status)
      rescue Exception => e
        puts e.message + "\n\n"
        puts e.backtrace.join("\n")
      end
    end

    def self.prepare_config(argv)
      options = {}

      # Parse arguments
      opt = OptionParser.new do |opts|
        opts.on('-c', '--config Config')           {|v| options[:config_name] = v}
        opts.on('-e', '--environment Environment') {|v| options[:environment] = v}
      end

      opt.default_argv = ARGV.dup

      while opt.default_argv.length > 1
        begin
          opt.parse!
        rescue OptionParser::InvalidOption
          nil
        end
      end

      Moto::Lib::Config.load_configuration(options[:config_name] ? options[:config_name] : 'moto', options[:environment])

      if !config_test_runner
        Moto::Lib::Config.moto[:test_runner] = {}
      end

      if !config_test_generator
        Moto::Lib::Config.moto[:test_generator] = {}
      end

    end

    def self.config_test_runner
      Moto::Lib::Config.moto[:test_runner]
    end

    def self.config_test_generator
      Moto::Lib::Config.moto[:test_generator]
    end

    def self.run_parse(argv)
      # Default options
      options = {}
      options[:listeners] = []
      options[:run_name] = nil
      options[:suite_name] = nil
      options[:assignee] = nil
      options[:stop_on] = {error: false, fail: false, skip: false}

      # Parse arguments
      OptionParser.new do |opts|
        opts.on('-t', '--tests Tests', Array) {|v| options[:tests] = v}
        opts.on('-g', '--tags Tags', Array) {|v| options[:tags] = v}
        opts.on('-f', '--filters Filters', Array) {|v| options[:filters] = v}
        opts.on('-l', '--listeners Listeners', Array) {|v| options[:listeners] = v}
        opts.on('-r', '--runname RunName') {|v| options[:run_name] = v}
        opts.on('-s', '--suitename SuiteName') {|v| options[:suite_name] = v}
        opts.on('-a', '--assignee Assignee') {|v| options[:assignee] = v}
        opts.on('-c', '--config Config') {|v| options[:config_name] = v}
        opts.on('--threads ThreadCount', Integer) {|v| options[:threads] = v}
        opts.on('--attempts AttemptCount', Integer) {|v| options[:attempts] = v}
        opts.on('--stop-on-error') {options[:stop_on][:error] = true}
        opts.on('--stop-on-fail') {options[:stop_on][:fail] = true}
        opts.on('--stop-on-skip') {options[:stop_on][:skip] = true}
        opts.on('--dry-run') {options[:dry_run] = true}
        opts.on('-x', '--explicit-errors') {options[:explicit_errors] = true}
        opts.on('--log-level LogLevel') {|v| options[:log_level] = v}
        opts.on('--param-name ParamName') {|v| options[:param_name] = v}
      end.parse!

      if options[:tests]
        options[:tests].each do |path|
          path.sub!(%r{\/$}, '') # remove trailing "/"
        end
      end

      if options[:run_name].nil?
        options[:run_name] = evaluate_name(options[:tests], options[:tags], options[:filters])
      end

      # Runner configuration

      Moto::Lib::Config.moto[:test_runner][:thread_count] = options[:threads] if options[:threads]
      Moto::Lib::Config.moto[:test_runner][:test_attempt_max] = options[:attempts] if options[:attempts]
      Moto::Lib::Config.moto[:test_runner][:dry_run] = options[:dry_run] if options[:dry_run]
      Moto::Lib::Config.moto[:test_runner][:explicit_errors] = options[:explicit_errors] if options[:explicit_errors]

      # Test log level parsing

      if options[:log_level]
        Moto::Lib::Config.moto[:test_runner][:log_level] = case options[:log_level].downcase
        when 'info'   then Logger::INFO
        when 'warn'   then Logger::WARN
        when 'error'  then  Logger::ERROR
        when 'fatal'  then Logger::FATAL
        else Logger::DEBUG
        end
      else
        Moto::Lib::Config.moto[:test_runner][:log_level] = Logger::DEBUG
      end

      # Generator configuration
      Moto::Lib::Config.moto[:test_generator][:param_name] = options[:param_name] if options[:param_name]

      return options
    end

    def self.validate_parse(argv)
      # Default options
      options = {}
      options[:listeners] = []
      options[:run_name] = nil
      options[:suite_name] = nil
      options[:assignee] = nil

      # Parse arguments
      OptionParser.new do |opts|
        opts.on('-t', '--tests Tests', Array) {|v| options[:tests] = v}
        opts.on('-g', '--tags Tags', Array) {|v| options[:tags] = v}
        opts.on('-f', '--filters Filters', Array) {|v| options[:filters] = v}
        opts.on('-l', '--listeners Listeners', Array) {|v| options[:listeners] = v}
        opts.on('-r', '--runname RunName') {|v| options[:run_name] = v}
        opts.on('-s', '--suitename SuiteName') {|v| options[:suite_name] = v}
        opts.on('-a', '--assignee Assignee') {|v| options[:assignee] = v}
        opts.on('-c', '--config Config') {|v| options[:config_name] = v}
        opts.on('-p', '--tagregexpos RegexPositive') {|v| options[:validator_regex_positive] = v}
        opts.on('-n', '--tagregexneg RegexNegative') {|v| options[:validator_regex_negative] = v}
        opts.on('-h', '--hastags') {|v| options[:validate_has_tags] = v}
        opts.on('-d', '--hasdescription') {|v| options[:validate_has_description] = v}
        opts.on('-w', '--tagwhitelist TagWhitelist', Array) {|v| options[:tag_whitelist] = v}
      end.parse!

      if options[:tests]
        options[:tests].each do |path|
          path.sub!(%r{\/$}, '') # remove trailing "/"
        end
      end

      if options[:run_name].nil?
        options[:run_name] = evaluate_name(options[:tests], options[:tags], options[:filters])
      end

      return options
    end

    # Generate default name based on input parameters
    def self.evaluate_name(tests, tags, filters)
      name = ''

      if tests
        name << "Tests: #{tests.join(',')}  "
      end

      if tags
        name << "Tags: #{tags.join(',')}  "
      end

      if filters
        name << "Filters: #{filters.join(',')}  "
      end

      return name
    end

    # Parses attributes passed to the application when run by 'moto generate'
    def self.generate_parse(argv)
      options = {}

      OptionParser.new do |opts|
        opts.on('-t', '--test Test') {|v| options[:dir] = v}
        opts.on('-a', '--appname AppName') {|v| options[:app_name] = v}
        opts.on('-b', '--baseclass BaseClass') {|v| options[:base_class] = v}
        opts.on('-f', '--force') {options[:force] = true}
      end.parse!

      options[:dir] = options[:dir].underscore

      if options[:app_name].nil?
        options[:app_name] = 'MotoApp'
      end

      return options
    end

    def self.show_help
      puts "" "
      Moto (#{Moto::VERSION}) CLI Help:
      moto --version     Display current version



      Exemplary usage:
         moto run PARAMTERES
         moto generate PARAMETERS
         moto validate PARAMETERS



      =========
      MOTO RUN:
      =========
       -t, --tests       Path of tests to be executed. Root: moto-phq/tests/<TESTS PATH>
       -g, --tags        Tags of tests to be executed.
                         Use # MOTO_TAGS: TAGNAME in test to assign tag.
       -f, --filters     Tags that filter tests passed via -t parameter.
                         Only tests in appropriate directory, having all of the specified tags will be executed.
                         Use # MOTO_TAGS: TAGNAME1 in test to assign tag.
                         Use ~ to filter tests that do not contain specific tag, e.g. ~tag


       -e, --environment Environment constants and tests parametrized in certain way depend on this.
                         Without this param only `config/environment/common.rb` will be loaded.
                         If provided moto will try to load additionally `config/environment/NAME.rb` and apply changes
                         on top of already loaded common configuration.
       -c, --config      Name of the config, without extension, to be loaded from MotoApp/config/CONFIG_NAME.rb
                         Default: moto (which loads: MotoApp/config/moto.rb)


       -l, --listeners   Reporters to be used.
                         Defaults are Moto::Reporting::Listeners::ConsoleDots, Moto::Reporting::Listeners::JunitXml
                         One reporter that is always used: Moto::Reporting::Listeners::KernelCode
       -s, --suitename   Name of the test suite to which should aggregate the results of current test run.
                         Required when specifying MotoWebUI as one of the listeners.
       -r, --runname     Name of the test run to which everything will be reported when using MotoWebUI.
                         Default: Value of -g or -t depending on which one was specified.
       -a, --assignee    ID of a person responsible for current test run.
                         Can have a default value set in config/webui section.
       --threads         Thread count. Run tests in parallel.
       --attempts        Attempt count. Max number of test execution times if failed.

       --stop-on-error   Moto will stop test execution when an error is encountered in test results
       --stop-on-fail    Moto will stop test execution when a failure is encountered in test results
       --stop-on-skip    Moto will stop test execution when a skip is encountered in test results

       --dry-run         Moto will list all test cases which would be run with provided arguments

       --x, explicit-errors   Use for development of tests - each code error in test will be caught,
                              logged as would normally do but will be also additionaly re-thrown.
                              This will obviously stop execution of selected set of tests but will provide
                              full stack and error message to the developer.

       --log-level       Defines level at which Logger works. Use one of following: debug, info, warn, error, fatal.

       --param-name      Only parameters that contain provided string will be executed.



      ==============
      MOTO VALIDATE:
      ==============
       -t, --tests       Path of tests to be validate. Root: moto-phq/tests/<TESTS PATH>
       -g, --tags        Tags of tests to be validated.
                         Use # MOTO_TAGS: TAGNAME in test to assign tag.
       -f, --filters     Tags that filter tests passed via -t parameter.
                         Only tests in appropriate directory, having all of the specified tags will be executed.
                         Use # MOTO_TAGS: TAGNAME1 in test to assign tag.
                         Use ~ to filter tests that do not contain specific tag, e.g. ~tag


       -c, --config      Name of the config, without extension, to be loaded from MotoApp/config/CONFIG_NAME.rb
                         Default: moto (which loads: MotoApp/config/moto.rb)


       -l, --listeners   Reporters to be used.
                         Defaults are Moto::Reporting::Listeners::ConsoleDots, Moto::Reporting::Listeners::JunitXml
                         One reporter that is always used: Moto::Reporting::Listeners::KernelCode
       -s, --suitename   Name of the test suite to which should aggregate the results of current test run.
                         Required when specifying MotoWebUI as one of the listeners.
       -r, --runname     Name of the test run to which everything will be reported when using MotoWebUI.
                         Default: Value of -g or -t depending on which one was specified.
       -a, --assignee    ID of a person responsible for current test run.
                         Can have a default value set in config/webui section.

       -p, --tagregexpos       Regex which will be matched against tags joined on ','.
                               Validation will pass if there is a match.
       -n, --tagregexneg       Regex which will be matched against tags joined on ','.
                               Validation will pass if there is no match.
       -h, --hastags           Validates if tests have #MOTO_TAGS with any tags.
       -d, --hasdescription    Validates if tests have #DESC with any text.
       -w, --tagwhitelist      Only tags from the whitelist will be allowed.
                               Provide in format: tag1,tag2,tag3 etc.



      ==============
      MOTO GENERATE:
      ==============
       -t, --test        Path and name of the test to be created.
                         Examples:
                         -ttest_name          will create MotoApp/tests/test_name/test_name.rb
                         -tdir/test_name      will create MotoApp/tests/dir/test_name/test_name.rb
       -a, --appname     Name of the application. Will be also used as topmost module in test file.
                         Default: MotoApp
       -b, --baseclass   File, without extension, with base class from which test will derive. Assumes one class per file.
                         Examples:
                         -btest_base          will use the file in MotoApp/lib/test/test_base.rb
                         -bsubdir/test_base   will use the file in MotoApp/lib/test/subdir/test_base.rb
                         By default class will derive from Moto::Test
       -f, --force       Forces generator to overwrite previously existing class file in specified location.
                         You have been warned.
      " ""
    end

  end
end
