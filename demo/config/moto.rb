{
    test_runner: {
        thread_count: 5,
        test_repeats: 1,
        test_log_level: Logger::DEBUG,
        test_attempt_max: 3,
        test_attempt_sleep: 1,
        test_reattempt_on_error: false,
        test_reattempt_on_fail: false
    },
    test_reporter: {
        default_listeners: [Moto::Reporting::Listeners::ConsoleDots, Moto::Reporting::Listeners::JunitXml],
        listeners: {
            junit_xml: { output_file: 'junit_report.xml' },
            # MotoWebUI can be obtained from: http://github.com/koojav/motowebui
            webui:
                {
                    send_log_on_pass: false,
                    url: 'http://motowebui.host.com:3000'
                }
        }
    },
    clients: {
        website: {
            capybara: {
                default_driver: :chrome,
                default_selector: :css,
                polling_interval: 0.2,
            }
        }
    }
}
