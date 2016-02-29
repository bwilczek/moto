require 'optparse'
require 'yaml'

require_relative '../lib/cli'
require_relative '../lib/app_generator'

module Moto

  class Parser
  
    def self.run(argv)
      begin
        # TODO Generate app / Change the way parsing options goes so it doesnt generate them if they`re not needed
        case argv[0]
          when '--version' then puts Moto::VERSION
          when 'run' then Moto::Cli.run(run_parse(argv))
          when 'help' then show_help
          when 'generate' then Moto::AppGenerator.run(generate_parse(argv))
          else puts "Command '#{argv[0]}' not recognized. Type help for list of supported commands."
        end
      rescue Exception => e
        puts e.message
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
      options[:reporters] = []
      # TODO Mandatory env var in app config
      options[:config] = eval(File.read("#{MotoApp::DIR}/config/moto.rb"))
      options[:environments] = []
      options[:name] = ''
         
      # Parse arguments
      # TODO eval ?
      # TODO const 
      # TODO reporters should be consts - not strings
      OptionParser.new do |opts|
        opts.on('-t', '--tests Tests', Array) { |v| options[:tests ] = v }
        opts.on('-g', '--tags Tags', Array) { |v| options[:tags ] = v }
        opts.on('-r', '--reporters Reporters', Array) { |v| options[:reporters] = v }
        opts.on('-e', '--environments Environment', Array) { |v| options[:environments] = v }
        opts.on('-c', '--const Const') { |v| options[:const] = v }
        opts.on('-n', '--name Name') { |v| options[:name] = v }
        opts.on('-f', '--config Config') { |v| options[:config].deep_merge!( eval( File.read(v) ) ) }
      end.parse!

      if options[:name].empty?
        options[:name] = evaluate_name(options[:tags], options[:tests])
      end

      if options[ :config ][ :moto ][ :runner ][ :mandatory_environment ] && options[ :environments ].empty?
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
       -t, --tests    = Tests to be executed.
                        For eg. Tests\Failure\Failure.rb should be passed as Tests::Failure
       -r, --reporter = Reporters to be used.
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
