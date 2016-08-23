require 'capybara'
require 'capybara/poltergeist'
require_relative '../../lib/config'

module Moto
  module Clients

    class Website < Moto::Clients::Base

      ignore_logging(:session)

      def initialize
        register_grid_driver
        register_chrome_driver
        register_poltergeist_driver

        if config[:default_selector]
          Capybara.default_selector = config[:default_selector]
        end
      end

      # Returns Capybara session, if none was available for this thread it will create one.
      def session
        if Thread.current['capybara_session'].nil?
          Thread.current['capybara_session'] = Capybara::Session.new(config[:default_driver])
          Thread.current['capybara_session'].driver.browser.manage.window.maximize
        end

        Thread.current['capybara_session']
      end

      # @return [Hash] Config section for Capybara driver.
      def config
        Moto::Lib::Config.moto[:clients][:website][:capybara]
      end
      private :config

      def start_run

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
          client.timeout = 180
          Capybara::Selenium::Driver.new(app, browser: :chrome, http_client: client, desired_capabilities: { args: ['-no-sandbox']} )
        end
      end
      private :register_chrome_driver

      def register_poltergeist_driver
        #Capybara.javascript_driver = :poltergeist
        options =
          {
              screen_size: [1920,1080],
              js_errors: false,
              phantomjs_options: ['--ignore-ssl-errors=yes'],

          }
        Capybara.register_driver :poltergeist do |app|
          Capybara::Poltergeist::Driver.new(app, options)
        end
      end
      private :register_poltergeist_driver


      def handle_test_exception(test, exception)
        #Thread.current['capybara_session'].save_screenshot "#{test.dir}/#{test.filename}_#{Time.new.strftime('%Y%m%d_%H%M%S')}.png"
      end

    end
  end
end
