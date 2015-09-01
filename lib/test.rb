module Moto
  class Test
    
    include Moto::Assert
    
    attr_writer :context
    attr_accessor :result
    attr_reader :name
    attr_reader :env
    attr_reader :params
    attr_writer :static_path

    class << self
      attr_accessor :_path
    end
    
    def self.inherited(k)
      k._path = caller.first.match( /(.+):\d+:in/ )[1]
    end
    
    def path
      self.class._path
    end
    
    def initialize
      # @context = context
      @result = Moto::Result::PENDING
    end

    def init(env, params)
      @env = env
      @params = params
      set_name
    end

    def logger
      @context.logger
    end

    def set_name
      if @env == :__default 
        return @name = "#{self.class.to_s}" if @params.empty?
        return @name = "#{self.class.to_s}/#{@params['__name']}" if @params.key?('__name')
      else
        return @name = "#{self.class.to_s}/#{@env}" if @params.empty?
        return @name = "#{self.class.to_s}/#{@env}/#{@params['__name']}" if @params.key?('__name')
      end
      @name = self.class.to_s
    end

    def dir
      # puts self.class.path
      return File.dirname(@static_path) unless @static_path.nil?
      File.dirname(self.path)
    end
    
    def filename
      return File.basename(@static_path, ".*") unless @static_path.nil?
      File.basename(path, ".*")
    end
 
    def const(key)
      @context.const(key)
    end

    def run
      # abstract
    end

    def before
      # abstract
    end

    def after
      # abstract
    end

    def client(name)
      @context.client(name)
    end
 
    def skip(msg = nil)
      if msg.nil?
        msg = "Test skipped with no reason given."
      else
        msg = "Skip reason: #{msg}"
      end
      raise Exceptions::TestSkipped.new msg
    end

    def fail(msg = nil)
      if msg.nil?
        msg = "Test failed with no reason given."
      else
        msg = "Fail reason: #{msg}"
      end
      raise Exceptions::TestFailed.new msg
    end

    def pass(msg = nil)
      if msg.nil?
        msg = "Test passed with no reason given."
      else
        msg = "Pass reason: #{msg}"
      end
      raise Exceptions::TestPassed.new msg
    end

  end
end