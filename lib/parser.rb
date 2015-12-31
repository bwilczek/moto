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
          when 'run' then Moto::Cli.run run_parse(argv)
          when 'help' then show_help
          when 'generate' then Moto::AppGenerator.run generate_parse(argv)
          else puts "Command '#{argv[0]}' not recognized. Type help for list of supported commands."
        end
      rescue Exception => e
        puts e.message
      end
    end
    
    def self.run_parse(argv)

      # TODO: fix this dumb verification of current working directory.
      unless File.exists? "#{MotoApp::DIR}/config/moto.rb"
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
      options[:name] = ""
         
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
        opts.on('-f', '--config Config') { |v| options[:config] = options[:config].merge( eval( v ) ) }
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
      tags ||= ""
      tests ||= ""
      if !tags.empty? && !tests.empty?
        return "#{tags.count} tags + #{tests.count} tests"
      elsif tags.empty?
        return tests.count == 1 ? "Test: #{tests.first}" : "#{tests.count} tests"
      elsif tests.empty?
        return tags.count == 1 ? "Tag: #{tags.first}" : "#{tags.count} tags"
      end
    end
    
    def self.generate_parse(argv)
      options = {}
      options[:dir]
    end
    
    def self.show_help
      puts """
      Moto (#{Moto::VERSION}) CLI Help:
      moto --version Display current version
      moto run:      
       -t, --tests = Tests to be executed. For e.x Tests\Failure\Failure.rb should be passed as Tests::Failure
       -r, --reporter = Reporters to be used. Defaults are Moto::Listeners::ConsoleDots, Moto::Listeners::JunitXml
       -e, --environment etc etc
      moto generate:
      moto generate app_name -d, --dir = directory. Default is current dir.
      """
    end
    
  end
end
