require 'optparse'
require 'yaml'

require_relative '../lib/cli'
require_relative '../lib/app_generator'

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

      rescue Exception => e
        puts e.message + "\n\n"
        puts e.backtrace.join("\n")
      end
    end

    def self.run_parse(argv)

      # TODO: fix this dumb verification of current working directory.
      if !File.exists? "#{MotoApp::DIR}/config/moto.rb"
        msg = "Config file (config/moto.rb) not present.\n"
        msg << 'Does current working directory contain Moto application?'
        raise msg
      end

      require 'bundler/setup'
      Bundler.require

      # Default options
      options = {}
      options[:listeners] = []
      # TODO Mandatory env var in app config
      options[:config] = eval(File.read("#{MotoApp::DIR}/config/moto.rb"))
      options[:environments] = []
      options[:name] = ''

      # Parse arguments
      # TODO eval ?
      # TODO const 
      # TODO listeners should be consts - not strings
      OptionParser.new do |opts|
        opts.on('-t', '--tests Tests', Array)              { |v| options[:tests ] = v }
        opts.on('-g', '--tags Tags', Array)                { |v| options[:tags ] = v }
        opts.on('-l', '--listeners Listeners', Array)      { |v| options[:listeners] = v }
        opts.on('-e', '--environments Environment', Array) { |v| options[:environments] = v }
        opts.on('-c', '--const Const')                     { |v| options[:const] = v }
        opts.on('-n', '--name Name')                       { |v| options[:name] = v }
        opts.on('-f', '--config Config')                   { |v| options[:config].deep_merge!( eval( File.read(v) ) ) }
      end.parse!

      if options[:name].empty?
        options[:name] = evaluate_name(options[:tags], options[:tests])
      end

      if options[ :config ][ :moto ][ :test_runner ][ :mandatory_environment ] && options[ :environments ].empty?
        puts 'Environment is mandatory for this project.'
        exit 1
      end

      return options
    end

    def self.evaluate_name(tags, tests)
      tags ||= ''
      tests ||= ''
      if !tags.empty? && !tests.empty?
        return "#{tags.count} tags + #{tests.count} tests"
      elsif tags.empty?
        return tests.count == 1 ? "Test: #{tests.first}" : "#{tests.count} tests"
      elsif tests.empty?
        return tags.count == 1 ? "Tag: #{tags.first}" : "#{tags.count} tags"
      end
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

      moto run:      
       -t, --tests     = Tests to be executed.
                         For eg. Tests\Failure\Failure.rb should be passed as Tests::Failure
       -l, --listeners = Reporters to be used.
                         Defaults are Moto::Listeners::ConsoleDots, Moto::Listeners::JunitXml
       -e, --environment etc etc


      moto generate:
       -t, --test      = Path and name of the test to be created.
                         Examples:
                         -ttest_name          will create MotoApp/tests/test_name/test_name.rb
                         -tdir/test_name      will create MotoApp/tests/dir/test_name/test_name.rb
       -a, --appname   = Name of the application. Will be also used as topmost module in test file.
                         Default: MotoApp
       -b, --baseclass = File (WITHOUT EXTENSION) with base class from which test will derive. Assumes one class per file.
                         Examples:
                         -btest_base          will use the file in MotoApp/lib/test/test_base.rb
                         -bsubdir/test_base   will use the file in MotoApp/lib/test/subdir/test_base.rb
                         By default class will derive from Moto::Test
       -f, --force     = Forces generator to overwrite previously existing class file in specified location.
                         You have been warned.
      """
    end

  end
end
