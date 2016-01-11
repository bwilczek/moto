{
  moto: {
    runner: {
      thread_count: 3,
      default_listeners: [Moto::Listeners::ConsoleDots],
      mandatory_environment: false,
    },
    thread_context: {
      log_level: Logger::DEBUG,
      max_attempts: 1,
    },
    listeners: {
      junit_xml: {
        # output_file: "junit_#{DateTime.now.strftime("%Y-%m-%d_%H%M%S")}.xml",
        output_file: "junit_report.xml"
      },
      webui: {
        # url: "http://your_address:3000"
      }
    },
    clients: {
      website: {
        capybara: {
          default_driver: :selenium,
          default_selector: :css,
          polling_interval: 0.2,
        }
      }
    }
  }
}