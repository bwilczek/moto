# moto

## Introduction
`moto` is a testing framework dedicated for functional testing - particularly for web applications. The main motivation behind this project is to make the test developer write as little code as possible to get the tests running. To some degree one might say that this framework implements `rails` paradigm for testing.

## Basic concepts
### Tests are an application
`moto` tests project is a separate application, which follows some standards in file naming and location. Following few simple rules can significantly reduce amount of code that has to be written in order to run the tests. `moto` will generate the scaffodling of the application as well an empty test scripts.

### Test script contains only test logic
No need to declare test class inheriting from some parent, or declare any `_test` methods - `moto` will do this for you. 

### Keeping tests DRY
Any logic that could be reused between tests can be easily extracted to objects called `Clients`. Example `client` can be a web brower session (`Capybara`) or a SOAP client (`Savon`) or a database connection. `Website` client comes with a handy mechanism of `Pages`, which to some extent implements `PageObjects` pattern.

Another way of reusing tests is implmented by concept of `environments` which allows running same scenario on different servers in the same execution to see first hand that things that work well on `integration` might not work on `staging`.

Tests can also be parametrized, so that once scenario is executed multiple times with different sets of parameters.

### Logging & reporting
Test execution details can be reported in different ways: from simple console output to storing full details in the database, or saving `junit`-like XML file - friendly for any CI system.

Every `Client` method call is logged into test execution log giving full trace of what went wrong. Standard Ruby `Logger` class is used for this purpose and log level is configurable. Writing to log file directly from the test is also supported so that debugging is made much easier.

### and more
1. flexible configuration
2. support for multi-threading
3. multiple ways of selecting tests for execution (single, list, directory, tag)
4. ... more to come as development is in progress

## More details
### Framework architecture
runner, thread_context, test, result

### Generating project and sample tests
under construction

### Test API
When in test files the following methods are available:

* `const('key')` - read const value specific for current environment from `config/const.yml` file
* `logger.info(msg)` - write message to test execution log file. See Ruby Logger class for details.
* `client('Website')` - access client object instance for given class name.
* `skip(optional_reason)` - skip this test execution
* `pass(optional_reason)` - forcibly pass this test and finish execution immediatelly
* `fail(optional_reason)` - forcibly fail this test and finish execution immediatelly
* `assert_equal(a, b)` - assertion, see module `Moto::Assert` for more assertion methods
* `dir` - current test directory
* `filename` - current test file name with no extension

### `Client` API
When editing `client` classes the following methods are available:

* `const('key')` - read const value specific for current environment from `config/const.yml` file
* `context.runner.my_config[:capybara][:default_driver]` - read config values for current class (here: `Moto::Clients::Website`) from `config/moto.rb` file
* `logger.info(msg)` - write message to test execution log file. See Ruby Logger class for details.
* `current_test` - reference to currently running test
* `client('Website')` - access other client object instance for given class name.

### Creating your own `client`
under construction 

### Using `Website` client and creating your own `Pages`
When editing `page` classes the following methods are available:

* `session` - reference to `Capybara` session
* `page('Login')` - reference to other `page` object. Here: `MotoApp::Clients::WebsitePages::Login`
* `const('key')` - read const value specific for current environment from `config/const.yml` file
* `context.runner.my_config[:capybara][:default_driver]` - read config values for current class (here: `Moto::Clients::Website`) from `config/moto.rb` file
* `logger.info(msg)` - write message to test execution log file. See Ruby Logger class for details.
* `current_test` - reference to currently running test
* `client('Website')` - access other client object instance for given class name.

### Environments
under construction

### Configuration
Configuration is defined on 2 levels:

* Environment specific constants for the application under test stored in `config/const.yml`. Access by `context.const`
* Configuration for the framework and project classes stored in `config/moto.rb`. Access by `context.runner.my_config`

### Creating your own `listener`
under construction

