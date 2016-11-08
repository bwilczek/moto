module Moto
  module Test
    # Provides tools for accessing metadata embedded in test files
    class Metadata

      # Absolute test path
      attr_reader :test_path

      # @param [String] test_path Absolute path to file with test
      def initialize(test_path)
        @test_path = test_path
      end

      # Text of the file with test
      # TODO: Remake to store only text related to metatags, not whole file
      def test_plaintext
        if @test_plaintext.nil?
          @test_plaintext = File.read(@test_path)
        end

        @test_plaintext
      end

      # @return [Array] of [String] which represent contents of #MOTO_TAGS
      def tags
        if @tags.nil?
          matches = test_plaintext.match(/^#(\s*)MOTO_TAGS:(.*?)$/)

          if matches
            @tags = matches.to_a[2].gsub(/\s*/, '').split(',')
          else
            @tags = []
          end
        end

        @tags
      end

      # @return [String] which represents contents of #TICKET_URL
      def ticket_url
        if @ticket_url.nil?
          matches = test_plaintext.match(/^#(\s*)TICKET_URL:(.*?)$/)

          if matches
            @ticket_url = matches.to_a[2].gsub(/\s*/, '')
          else
            @ticket_url = ''
          end
        end

        @ticket_url
      end

      # Overriden eql? so various comparisons, array substractions etc. can be perfromed on
      # Metadata objects with them being represented by test's location
      def eql?(other)
        if self.class == other.class
          return self.test_path == other.test_path
        end

        false
      end

    end
  end
end