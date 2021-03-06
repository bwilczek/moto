require 'thread'
require_relative '../../test/generator'

# Thread safe provider of test instances

module Moto
  module Modes
    module Run
      class TestProvider

        # @param [Array] tests_metadata
        def initialize(tests_metadata)
          super()
          @test_repeats = Moto::Config::Manager.config_moto[:test_runner][:test_repeats]
          @current_test_repeat = 1
          @queue = Queue.new
          @tests_metadata = tests_metadata
          @test_generator = Moto::Test::Generator.new
        end

        # Use this to retrieve tests safely in multithreaded environment
        def get_test
          create_tests
          @queue.pop
        end

        # Pushes new tests to the queue if possible and the queue is already empty
        def create_tests
          if @queue.empty?

            test_metadata = get_test_metadata

            if test_metadata
              test_variants = @test_generator.get_test_with_variants(test_metadata)
              test_variants.each do |test|
                @queue.push(test)
              end
            end

          end
        end
        private :create_tests

        # Returns metadata of the test while supporting the number of repeats specified by the user
        # return [Moto::Test::Metadata]
        def get_test_metadata

          if @current_test_repeat == 1
            @test_metadata = @tests_metadata.shift
          end

          test_metadata = Marshal.load(Marshal.dump(@test_metadata))

          if test_metadata
            test_metadata.test_repeat = @current_test_repeat
          end

          if @current_test_repeat == @test_repeats
            @current_test_repeat = 1
          else
            @current_test_repeat += 1
          end

          test_metadata
        end
        private :get_test_metadata

        # Number of threads waiting for a job
        def num_waiting
          @queue.num_waiting
        end

      end
    end
  end
end

