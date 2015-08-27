require 'trollop'
require 'optparse'
require 'yaml'

require_relative '../lib/cli'

module Moto

  class Parser
  
    def self.run(argv)
            
      # TODO Generate app / Change the way parsing options goes so it doesnt generate them if they`re not needed
      case argv[0]
      when 'run' then Moto::Cli.run parse(argv)
      when 'help' then show_help
      end
    end
    
    def self.parse(argv)   
      puts Moto::DIR
      # Default options 
      options = {}
      options[ :reporter ] = [Moto::Listeners::ConsoleDots, Moto::Listeners::JunitXml] 
      options[ :config ] = eval(File.read("#{MotoApp::DIR}/config/moto.rb"))  
         
      # Parse arguments
      # TODO eval ?
      # TODO const 
      OptionParser.new do |opts|       
          opts.on('-t', "--tests Tests", Array) { |v| options[:tests ] = v }
          opts.on('-r', '--reporter Reporter') { |v| options[ :reporter ] = v }
          opts.on('-e', '--environment Environment') { |v| options[ :environment ] = v }
          opts.on('-c', '--const Const') { |v| options[ :const ] = v }
          opts.on('-cfg', '--config Config') { |v| options[ :config ] = options[ :config ].merge( eval( v ) ) }
      end.parse!
      
      return options
    end
    
    def self.show_help
      puts """
      Moto CLI Help:
      moto run:
       -t, --tests = Tests to be executed. For e.x Tests\Failure\Failure.rb should be passed as Tests::Failure
       -r, --reporter = Reporters to be used. Defaults are Moto::Listeners::ConsoleDots, Moto::Listeners::JunitXml
       -e, --environment etc etc
      moto generate:
      """
    end
    
    
    
  end
end
