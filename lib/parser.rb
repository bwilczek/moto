require 'optparse'
require 'yaml'

require_relative '../lib/cli'
require_relative '../lib/app_generator'

module Moto

  class Parser
  
    def self.run(argv)
            
      # TODO Generate app / Change the way parsing options goes so it doesnt generate them if they`re not needed
      case argv[0]
      when 'run' then Moto::Cli.run run_parse(argv)
      when 'help' then show_help
      when 'generate' then Moto::AppGenerator.run generate_parse(argv)
      end
    end
    
    def self.run_parse(argv)   
      # puts Moto::DIR
      # Default options 
      options = {}
      options[:reporters] = [Moto::Listeners::ConsoleDots, Moto::Listeners::JunitXml] 
      options[:config] = eval(File.read("#{MotoApp::DIR}/config/moto.rb"))
      options[:environments] = []
         
      # Parse arguments
      # TODO eval ?
      # TODO const 
      # TODO reporters should be consts - not strings
      OptionParser.new do |opts|       
          opts.on('-t', "--tests Tests", Array) { |v| options[:tests ] = v }
          opts.on('-r', '--reporters Reporters', Array) { |v| options[:reporters] = v }
          opts.on('-e', '--environments Environment', Array) { |v| options[:environments] = v }
          opts.on('-c', '--const Const') { |v| options[:const] = v }
          opts.on('-cfg', '--config Config') { |v| options[:config] = options[:config].merge( eval( v ) ) }
      end.parse!
      return options
    end
    
    def self.generate_parse(argv)
      options = {}
      options[:dir]
    end
    
    def self.show_help
      puts """
      Moto CLI Help:
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
