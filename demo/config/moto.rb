{
    test_runner: {
        thread_count: 5,
        test_repeats: 1,
        test_log_level: Logger::DEBUG,
        test_attempt_max: 3,
        test_attempt_sleep: 1
    },
    test_reporter: {
        default_listeners: [Moto::Reporting::Listeners::ConsoleDots, Moto::Reporting::Listeners::JunitXml],
        listeners: {
            junit_xml: { output_file: 'junit_report.xml' },
            webui: { url: 'http://your.address.com:3000' }
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
