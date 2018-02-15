# Moto Framework

## Introduction
`moto` is a testing framework dedicated for functional testing.  
The main motivation behind this project is to make the test developer write as little code as possible to get the tests running.

## Basic concepts
### Structure
Moto is delivered in form of a gem, executed from a directory where moto-based tests are stored.  
Configuration overhead is minimal - simple folder structure is needed for `moto` to be able to recognize appropriate files.  

### Tests
Each test is a separate class which derives from `Moto::Test::Base` and needs to implement `run()` method where it's logic is described.

### DRY
Tests can also be parametrized, so that a single scenario is executed multiple times with different sets of parameters.  
Each parametrized variant of a scenario is then treated, result-wise, as a separate test entity.

### Result reporting and summary
Test execution details can be reported in multiple ways:
#### 1. **Console output**: compact and more descriptive console reportes are available out of the box
#### 2. **XML**: JUnit file
#### 3. **[MotoWebUI](https://github.com/Koojav/motowebui)**: Easily deployable web interface for viewing and managing test results is available as a separate project.
#### 4. **Open Source**: additional reporters-listeners can be easily added to fit any project.

Every method call is logged into test execution log giving full trace of what went wrong. 
Standard Ruby `Logger` class is used for this purpose and log level is configurable. 
Writing to log file directly from the test is also supported so that debugging is made much easier. 

## Configuration
### 1. Flexible configuration with parameters or configuration file
### 2. Multi-threading supported
### 3. Multiple environments supported with configuration files
### 4. Many ways to select full/sub-set of tests to be executed: tags, directories

## Additional features
### 1. Test template generation via `moto generate`
### 2. Test structure/description/tags validation via `moto validate`
### 3. Dry-run available via `moto run --dry-run` 

## Usage
Copy directory: `demo`, adjust to your needs and from that directory execute `moto run` - for list of available options please see help (just type `moto`).

### Test API
From test class' level the following methods/fields are available:

* `const('key')` - read const value specific for current environment from `config/const.yml` file
* `logger.info(msg)` - write message to test execution log file. See Ruby Logger class for details.
* `client('Website')` - access client object instance for given class name.
* `skip(optional_reason)` - skip this test execution
* `pass(optional_reason)` - forcibly pass this test and finish execution immediatelly
* `fail(optional_reason)` - forcibly fail this test and finish execution immediatelly
* `assert_equal(a, b)` - assertion, see class `Moto::Test::Base` for more assertion methods
* `assert(condition, failure message)` - assertion, see class `Moto::Test::Base` for more assertion methods
* `dir` - current test directory
* `filename` - current test file name with no extension
* `run` - body of the test to be executed
* `before` - invoked before run(). optional
* `after` - invoked after run(), even if there was an error in run(), optional
* `status` - info about execution status of the test (failures, problems etc.)

### Environment

* Environment specific constants for the application under test are stored in two types of files:
* `config/environments/common.rb` -  constants common for all the environments
* `config/environments/ENVNAME.rb` - constants specific for environment specified with -e ENVNAME when running moto
*
* Both types of files should contain just ruby hashes with keys and values. They will be automatically deep merged by
* moto and can be accessed by `Moto::Config::Manager.config_environment` - this will return `Moto::Config::Hash` which derives from `Hash` 
and allows for safer monkey patching custom methods which return and/or combine different keys from config files.
*
* Please refer to rdoc in appropriate class for further information.

### Configuration

* Configuration for the framework and project classes stored in `config/moto.rb`.
* File should contain only hash with appropriate key/value pairs.
*
* Access by `Moto::Config::Manager.config_moto`

### Creating your own `listener`
Custom listeners need to derive from `Moto::Reporting::Listeners::Base`  
Code documentation in that class explains all the details

