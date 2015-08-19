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
under constuction (access to logger, client, params, own directory, thread_context)

### Creating your own `client`
under construction 

### Using `Website` client and creating your own `Pages`

### Environments
under construction

### Configuration
under construction

### Creating your own `listener`
under construction

