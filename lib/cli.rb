require 'logger'
require 'pp'
require 'yaml'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
# require 'active_support/core_ext'

APP_DIR = Dir.pwd
MOTO_DIR = File.dirname(File.dirname(__FILE__))

# TODO detect if cwd contains MotoApp

require "#{APP_DIR}/config/moto"

require_relative './empty_listener'
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
require_relative './test_generator'

module Moto

  class Cli
  
    def self.run(argv)
      test_class_name = argv[0]
      
      tg = TestGenerator.new(APP_DIR)
      t = tg.generate(test_class_name)
      
      tests = [t]
      
      # parsing ARGV and creating config will come here
      # instantiation of tests for ARGV params also happens here
      # instantiate listeners/reporters
      
      # listeners = []
      listeners = [Moto::Listeners::Console]
      runner = Moto::Runner.new(tests, listeners, thread_cnt: 3, environments: [:qa, :qa2])
      runner.run
    end
  
  end
end
