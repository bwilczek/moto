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
      def text
        if @text.nil?
          @text = ''

          File.foreach(@test_path) do |line|

            # Read lines of file until class specification begins
            if line.match(/^\s*(class|module)/)
              break
            end

            @text += line
          end

        end

        @text
      end
      private :text

      # @return [Array] of [String] which represent contents of #MOTO_TAGS
      def tags
        if @tags.nil?
          matches = text.match(/^#(\s*)MOTO_TAGS:(.*?)$/)

          if matches
            @tags = matches.to_a[2].gsub(/\s*/, '').split(',')
          else
            @tags = []
          end
        end

        @tags
      end

      # @return [Array] of [String] which represent contents of #TICKET_URL
      def ticket_urls
        if @ticket_urls.nil?
          matches = text.match(/^#(\s*)TICKET_URLS:(.*?)$/)

          if matches
            @ticket_urls = matches.to_a[2].gsub(/\s*/, '').split(',')
          else
            @ticket_urls = []
          end
        end

        @ticket_urls
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