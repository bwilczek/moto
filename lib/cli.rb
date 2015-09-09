# TODO: fix this dumb verification of current working directory
unless File.exists? "#{Dir.pwd}/config/moto.rb"
  puts "Config file (config/moto.rb) not present."
  puts "Does current working directory contain Moto application?"
  exit 1
end

require 'logger'
require 'pp'
require 'yaml'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'

require 'bundler/setup'
Bundler.require

module MotoApp
  DIR = Dir.pwd
end

module Moto
  DIR = File.dirname(File.dirname(__FILE__))
end

require_relative './empty_listener'
require_relative './forward_context_methods'
require_relative './test_logging'
require_relative './runner_logging'
require_relative './runner'
require_relative './thread_context'
require_relative './result'
require_relative './assert'
require_relative './test'
require_relative './page'
require_relative './clients/base'
require_relative './listeners/base'
require_relative './listeners/console'
require_relative './listeners/console_dots'
require_relative './listeners/junit_xml'
require_relative './test_generator'
require_relative './exceptions/moto'
require_relative './exceptions/test_skipped'
require_relative './exceptions/test_forced_failure'
require_relative './exceptions/test_forced_passed'

module Moto

  class Cli
  
    def self.run(argv)
      tests = []
        argv[ :tests ].each do |test_name|
        test_class_name = test_name
              
        tg = TestGenerator.new(MotoApp::DIR)
        t = tg.generate(test_class_name)      
        tests << t
      end
     
      runner = Moto::Runner.new(tests, argv[ :reporters ], argv[ :environments ], argv[ :config ])
      runner.run
    end
  
  end
end
