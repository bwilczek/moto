module Moto
  module RunnerLogging


    # TODO: merge it somehow with TestLogging. Parametrize logger object?
    def self.included(cls)
      def cls.method_added(name)
        excluded_methods = Moto::EmptyListener.instance_methods(false)
        excluded_methods << :new
        excluded_methods << :initialize
        # TODO: configure more excluded classes/methods
        return if @added 
        @added = true # protect from recursion
        original_method = "original_#{name}"
        alias_method original_method, name
        define_method(name) do |*args|
          @context.runner.logger.debug("#{self.class.name}::#{__callee__} ENTER >>> #{args}") unless excluded_methods.include? name 
          result = send original_method, *args
          @context.runner.logger.debug("#{self.class.name}::#{__callee__} LEAVE <<< #{result} ") unless excluded_methods.include? name
          result
        end
        @added = false
      end

    end    
  end
end