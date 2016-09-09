# moto

## Introduction
`moto` is a testing framework dedicated for functional testing. The main motivation behind this project is to make the test developer write as little code as possible to get the tests running. To some degree one might say that this framework implements `rails` paradigm for testing.

## Basic concepts
### Tests are an application
`moto` tests project is a separate application, which follows some standards in file naming and location. Following a few simple rules can significantly reduce amount of code that has to be written in order to run the tests. `moto` will generate the scaffodling of the application as well an empty test scripts.

### Test script contains only test logic
No need to declare test class inheriting from some parent, or declare any `_test` methods - `moto` will do this for you. 

### Keeping tests DRY
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
When in test files the following methods/fields are available:

* `const('key')` - read const value specific for current environment from `config/const.yml` file
* `logger.info(msg)` - write message to test execution log file. See Ruby Logger class for details.
* `client('Website')` - access client object instance for given class name.
* `skip(optional_reason)` - skip this test execution
* `pass(optional_reason)` - forcibly pass this test and finish execution immediatelly
* `fail(optional_reason)` - forcibly fail this test and finish execution immediatelly
* `assert_equal(a, b)` - assertion, see class `Moto::Test::Base` for more assertion methods
* `dir` - current test directory
* `filename` - current test file name with no extension
* `run` - body of the test to be executed
* `before` - invoked before run()
* `after` - invoked after run(), even if there was an error in run()
* `status` - info about execution status of the test (failures, problems etc.)

### Using `Website` client and creating your own `Pages`
When editing `page` classes the following methods are available:

* `session` - reference to `Capybara` session
* `page('Login')` - reference to other `page` object. Here: `MotoApp::Clients::WebsitePages::Login`
* `const('key')` - read const value specific for current environment from `config/const.yml` file
* `context.moto_app_config` - read config from YAML files in ./config
* `logger.info(msg)` - write message to test execution log file. See Ruby Logger class for details.
* `current_test` - reference to currently running test
* `client('Website')` - access other client object instance for given class name.

### Environment

* Environment specific constants for the application under test are stored in two types of files:
* `config/environments/common.rb` -  constants common for all the environments
* `config/environments/ENVNAME.rb` - constants specific for environment specified with -e ENVNAME when running moto
*
* Both types of files should contain just ruby hashes with keys and values. They will be automatically deep merged by
* moto and can be accessed by `Moto::Lib::Config.environment_const(key)`
*
* Please refer to rdoc in appropriate class for further information.

### Configuration

* Configuration for the framework and project classes stored in `config/moto.rb`.
* File should contain only hash with appropriate key/value pairs.
*
* Access by `Moto::Lib::Config.moto`

### Creating your own `listener`
Custom listeners need to derive from Moto::Reporting::Listeners::Base  
Code documentation in that class explains all the details

