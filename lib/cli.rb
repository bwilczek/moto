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
      test_paths_absolute = []
      test_classes = []

      #
      unless argv[ :tests ].nil?
        argv[ :tests ].each do |test_path_relative|
          test_path_absolute = "#{MotoApp::DIR}/tests/"+test_path_relative.downcase
          a = test_path_absolute.split('/')
          test_path_absolute = (a+[a[-1]]).join('/') + ".rb"
          test_paths_absolute.include?(test_path_absolute) || test_paths_absolute << test_path_absolute
        end
      end

      unless argv[ :directories ].nil?
        argv[ :directories ].each do |dir_name|
          test_paths = Dir.glob("#{MotoApp::DIR}/tests/#{dir_name}/**/*.rb")
          test_paths = test_paths - test_paths_absolute
          test_paths_absolute += test_paths
        end
      end

      # TODO Optimization for files without #MOTO_TAGS
      unless argv[ :tags ].nil?
        tests_total = Dir.glob("#{MotoApp::DIR}/tests/**/*.rb")
        argv[ :tags ].each do |tag_name|
          tests_total.each do |test_dir|
            test_body = File.read (test_dir)
            test_body.each_line do |line|
              line = line.delete(' ')
              if line.include?( '#MOTO_TAGS')
                if line.include? (tag_name + ",")
                  test_paths_absolute.include?(test_dir) || test_paths_absolute << test_dir
                  break
                else
                  break
                end
              end
            end
          end
        end
      end

      tg = TestGenerator.new(MotoApp::DIR)
      test_paths_absolute.each do |test_path|
        test_classes << tg.generate(test_path)
      end

      listeners = []
      argv[ :reporters ].each do |r|
        listeners << r.constantize
      end
      
      runner = Moto::Runner.new(test_classes, listeners, argv[ :environments ], argv[ :config ])
      runner.run
    end
  
  end
end
