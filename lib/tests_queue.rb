require 'thread'

module Moto
  class TestsQueue < Queue

    def initialize(test_paths_absolute)
      super()
      @test_generator = Moto::TestGenerator.new(test_paths_absolute)
    end

    def get_test
      if self.empty?

        test_variants = @test_generator.get_test_with_variants

        if test_variants
          test_variants.each do |test|
            self.push(test)
          end
        end

      end

      self.pop
    end

  end
end

