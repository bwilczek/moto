module MotoApp
  DIR = Dir.pwd
end

require_relative 'metadata'
require_relative '../version'
require_relative '../config/manager'

module Moto
  module Test
    class MetadataGenerator

      def self.generate(directories = nil, tags = nil, filters = nil)
        tests_metadata = []

        if directories
          directories.each do |directory|
            Dir.glob("#{MotoApp::DIR}/tests/#{directory}/**/*.rb").each do |test_path|
              tests_metadata << Moto::Test::Metadata.new(test_path)
            end
          end
        end

        if tags
          tests_total = Dir.glob("#{MotoApp::DIR}/tests/**/*.rb")
          tests_total.each do |test_path|

            metadata = Moto::Test::Metadata.new(test_path)
            tests_metadata << metadata unless (tags & metadata.tags).empty?

          end
        end

        # Make sure there are no repetitions in gathered set
        tests_metadata.uniq! {|metadata| metadata.test_path}

        # Filter tests by provied tags
        # - test must contain ALL tags specified with -f param
        # - use ~ for negation
        # - test may contain other tags
        if filters
          filters.each do |filter|
            filtered = tests_metadata.select do |metadata|
              next if metadata.tags.empty?
              filter_matches_any_tag?(filter, metadata.tags) || filter_negation_matches_none_tag?(filter, metadata.tags)
            end
            tests_metadata &= filtered
          end
        end

        # TODO: THIS SHOULDN'T BE HERE - REMNANT OF THE PAST
        # Requires custom initializer if provided by application that uses Moto
        if File.exists?("#{MotoApp::DIR}/lib/initializer.rb")
          require("#{MotoApp::DIR}/lib/initializer.rb")
          initializer = MotoApp::Lib::Initializer.new
          initializer.init
        end

        return tests_metadata
      end

      def self.filter_matches_any_tag?(filter, tags)
        !filter.start_with?('~') && tags.any? {|tag| filter == tag}
      end
      private_class_method :filter_matches_any_tag?

      def self.filter_negation_matches_none_tag?(filter, tags)
        filter.start_with?('~') && tags.none? {|tag| filter[1..-1] == tag}
      end
      private_class_method :filter_negation_matches_none_tag?

    end
  end
end
