require 'thread'
require_relative 'test_generator'

module Moto
  module Runner
    # Thread safe provider of test instances
    class TestProvider

      # @param [Array] test_paths_absolute
      def initialize(test_paths_absolute, test_path_params)
        super()
        @test_repeats = Moto::Lib::Config.moto[:test_runner][:test_repeats]
        @current_test_repeat = 1
        @queue = Queue.new
        @test_paths_absolute = test_paths_absolute
        @test_generator = TestGenerator.new
        @test_path_params = test_path_params
      end

      # Use this to retrieve tests safely in multithreaded environment
      def get_test
        create_tests
        @queue.pop
      end

      # Pushes new tests to the queue if possible and the queue is already empty
      def create_tests
        if @queue.empty?

          test_variants = @test_generator.get_test_with_variants(get_test_path, @test_path_params)

          if test_variants
            test_variants.each do |test|
              @queue.push(test)
            end
          end

        end
      end
      private :create_tests

      # Returns path to the test while supporting the number of repeats specified by the user
      # return [String] Path to the test
      def get_test_path

        if @current_test_repeat == 1
          @test_path = @test_paths_absolute.shift
        end

        if @current_test_repeat == @test_repeats
          @current_test_repeat = 1
        else
          @current_test_repeat += 1
        end

        @test_path
      end
      private :get_test_path

      # Number of threads waiting for a job
      def num_waiting
        @queue.num_waiting
      end

    end
  end
end

