require 'optparse'
require 'yaml'

require_relative '../lib/cli'
require_relative '../lib/app_generator'
require_relative '../lib/config'
module Moto

  class Parser

    def self.run(argv)
      begin

        if argv[0] == '--version'
          puts Moto::VERSION
        elsif argv[0] == 'run' && argv.length > 1
          Moto::Cli.run(run_parse(argv))
        elsif argv[0] == 'generate' && argv.length > 1
          Moto::AppGenerator.run(generate_parse(argv))
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

    def self.run_parse(argv)
      require 'bundler/setup'
      Bundler.require

      # Default options
      options = {}
      options[:listeners]   = []
      options[:run_name]    = nil
      options[:suite_name]  = nil
      options[:assignee]    = nil
      options[:stop_on]     = {error: false, fail: false, skip: false}

      # Parse arguments
      OptionParser.new do |opts|
        opts.on('-t', '--tests Tests', Array)              { |v| options[:tests]        = v }
        opts.on('-g', '--tags Tags', Array)                { |v| options[:tags]         = v }
        opts.on('-f', '--filters Filters', Array)          { |v| options[:filters]      = v }
        opts.on('-l', '--listeners Listeners', Array)      { |v| options[:listeners]    = v }
        opts.on('-e', '--environment Environment')         { |v| options[:environment]  = v }
        opts.on('-r', '--runname RunName')                 { |v| options[:run_name]     = v }
        opts.on('-s', '--suitename SuiteName')             { |v| options[:suite_name]   = v }
        opts.on('-a', '--assignee Assignee')               { |v| options[:assignee]     = v }
        opts.on('-c', '--config Config')                   { |v| options[:config_name]  = v }
        opts.on('--threads ThreadCount', Integer)          { |v| options[:threads]      = v }
        opts.on('--attempts AttemptCount', Integer)        { |v| options[:attempts]     = v }
        opts.on('--stop-on-error')                         { options[:stop_on][:error] = true }
        opts.on('--stop-on-fail')                          { options[:stop_on][:fail]  = true }
        opts.on('--stop-on-skip')                          { options[:stop_on][:skip]  = true }
        opts.on('--dry-run')                               { options[:dry_run]         = true }
      end.parse!

      if options[:run_name].nil?
        options[:run_name] = evaluate_name(options[:tests], options[:tags], options[:filters])
      end

      if options[:environment]
        Moto::Lib::Config.environment = options[:environment]
        Moto::Lib::Config.load_configuration(options[:config_name] ? options[:config_name] : 'moto')
      else
        puts 'ERROR: Environment is mandatory.'
        Kernel.exit(-1)
      end

      Moto::Lib::Config.moto[:test_runner][:thread_count] = options[:threads] if options[:threads]
      Moto::Lib::Config.moto[:test_runner][:test_attempt_max] = options[:attempts] if options[:attempts]
      Moto::Lib::Config.moto[:test_runner][:dry_run] = options[:dry_run] if options[:dry_run]

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
        opts.on('-t', '--test Test') { |v| options[:dir ] = v }
        opts.on('-a', '--appname AppName') { |v| options[:app_name ] = v }
        opts.on('-b', '--baseclass BaseClass') { |v| options[:base_class] = v }
        opts.on('-f', '--force') { options[:force ] = true }
      end.parse!

      options[:dir] = options[:dir].underscore

      if options[:app_name].nil?
        options[:app_name] = 'MotoApp'
      end

      return options
    end

    def self.show_help
      puts """
      Moto (#{Moto::VERSION}) CLI Help:
      moto --version Display current version

      MOTO RUN:
       -t, --tests       Tests to be executed.
       -g, --tags        Tags of tests to be executed.
                         Use # MOTO_TAGS: TAGNAME in test to assign tag.
       -f, --filters     Tags that filter tests passed via -t parameter.
                         Only tests in appropriate directory, having all of the specified tags will be executed.
                         Use # MOTO_TAGS: TAGNAME1 in test to assign tag.


       -e, --environment Mandatory environment. Environment constants and tests parametrized in certain way depend on this.
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


      MOTO GENERATE:
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
      """
    end

  end
end
