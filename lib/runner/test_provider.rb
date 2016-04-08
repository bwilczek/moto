require 'thread'
require_relative 'test_generator'

module Moto
  module Runner
    # Thread safe queue of tests
    class TestProvider

      def initialize(test_paths_absolute, environments)
        super()
        @queue = Queue.new
        @test_paths_absolute = test_paths_absolute
        @test_generator = TestGenerator.new(environments)
      end

      # Thread safe way of requesting Test object creation.
      # @return [Moto::Test::Base]
      def get_test
        if @queue.empty?

          test_variants = @test_generator.get_test_with_variants(@test_paths_absolute.shift)

          if test_variants
            test_variants.each do |test|
              @queue.push(test)
            end
          end

        end

        @queue.pop
      end

      def num_waiting
        @queue.num_waiting
      end

    end
  end
end

