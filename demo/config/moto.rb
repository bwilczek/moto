{
    test_runner: {
        thread_count: 5,
        test_repeats: 1,
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
                    url: 'http://motowebui.host.com:3000',
                    # Optional, can be removed in order to let MotoWebUI decide what to do with TestRun without assignee
                    # Can also be set/overwritten by appropriate moto parametrization
                    default_assignee: 0
                }
        }
    },
    clients: {
        capybara: {
            browser: {
                type: 'chrome',       # 'chrome' (requires chromedriver), 'firefox' (requires geckodriver)
                dockerization: {
                    enabled: false,   # will use dockerized selenium + browser instead of locally installed
                    debug: false      # starts additional VNC server in container on port 5900
                },
                width: 1920,
                height: 1080
            },
            default_selector: :css,
            polling_interval: 0.2
        }
    }
}
