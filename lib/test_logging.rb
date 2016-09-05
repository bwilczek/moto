module Moto
  module TestLogging

    @@ignore_logging = []

    def self.included(cls)

      def cls.ignore_logging(method)
        full_name = "#{self.name}::#{method}"
        @@ignore_logging << full_name
      end
      
      def cls.method_added(name)

        @@ignore_logging << "#{self.name}::new"
        @@ignore_logging << "#{self.name}::initialize"

        return if @added
        @added = true # protect from recursion
        original_method = "original_#{name}"
        alias_method original_method, name
        define_method(name) do |*args|
          full_name = "#{self.class.name}::#{__callee__}"
          # TODO: use self.class.ancestors to figure out if ancestor::__callee__ is not in @@ignore_logging
          skip_logging = @@ignore_logging.include? full_name
          unless skip_logging
            self.class.ancestors.each do |a|
              ancestor_name = "#{a.name}::#{__callee__}"
              if @@ignore_logging.include? ancestor_name
                skip_logging = true
                break
              end
            end
          end
          Thread.current['logger'].debug("ENTER >>> #{self.class.name}::#{__callee__}(#{args})") unless skip_logging
          result = send original_method, *args
          # Below is the hack to properly escape binary data (if any manages to make it to logs)
          Thread.current['logger'].debug("LEAVE <<< #{self.class.name}::#{__callee__} => #{[result].to_s[1..-2]}") unless skip_logging
          result
        end
        @added = false
      end
    end

  end
end