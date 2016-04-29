require 'capybara'
require_relative '../../lib/config'

module Moto
  module Clients

    class Website < Moto::Clients::Base

      attr_reader :session

      ignore_logging(:page)
      ignore_logging(:context)
      ignore_logging(:session)

      def init
        register_grid_driver
        register_chrome_driver
      end

      # @return [Hash] Config section for Capybara driver.
      def config
        Moto::Lib::Config.moto[:clients][:website][:capybara]
      end
      private :config

      def start_run
        # TODO: make session driver configurable
        if config[:default_selector]
          Capybara.default_selector = config[:default_selector]
        end

        Thread.current['capybara_session'] = Capybara::Session.new(config[:default_driver])
        @pages = {}
      end

      def end_run
        Thread.current['capybara_session'].driver.quit
      end

      def start_test(test)
        Thread.current['capybara_session'].reset_session!
      end

      def end_test(test)
        Thread.current['capybara_session'].reset_session!
      end
      #TODO fix moto to use Lib module
      def page(p)
        page_class_name = "#{self.class.name}::Pages::#{p}"
        page_class_name.gsub!('Moto::', 'MotoApp::Lib::')
        if @pages[page_class_name].nil?
          a = page_class_name.underscore.split('/')
          page_path = a[1..-1].join('/')
          require "#{MotoApp::DIR}/#{page_path}"
          @pages[page_class_name] = page_class_name.constantize.new(self)
        end
        @pages[page_class_name]
      end

      def register_grid_driver
        grid_config = config[:grid]
        return if grid_config.nil?
        if grid_config[:capabilities].nil?
          capabilities = Selenium::WebDriver::Remote::Capabilities.firefox
        else
          capabilities = Selenium::WebDriver::Remote::Capabilities.new(grid_config[:capabilities])
        end
        Capybara.register_driver :grid do |app|
          Capybara::Selenium::Driver.new(app,
                                        :browser => :remote,
                                        :url => grid_config[:url],
                                        :desired_capabilities => capabilities)
        end
      end
      private :register_grid_driver

      def register_chrome_driver
        Capybara.register_driver :chrome do |app|
          client = Selenium::WebDriver::Remote::Http::Default.new
          Capybara::Selenium::Driver.new(app, browser: :chrome, http_client: client)
        end
      end
      private :register_chrome_driver


      def handle_test_exception(test, exception)
        #Thread.current['capybara_session'].save_screenshot "#{test.dir}/#{test.filename}_#{Time.new.strftime('%Y%m%d_%H%M%S')}.png"
      end

    end
  end
end
