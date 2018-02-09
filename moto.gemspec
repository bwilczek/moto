$:.push File.expand_path('../lib', __FILE__)

require 'version'

Gem::Specification.new do |s|
  s.name        = 'moto'
  s.version     = Moto::VERSION
  s.summary     = 'Moto - yet another testing framework'
  s.description = 'Lightweight framework for functional testing. Supports threading, scenario parametrization, different test environments and much more.'
  s.authors     = ['Bartek Wilczek', 'Maciej Stark', 'Radosław Sporny', 'Michał Kujawski']
  s.email       = ['bwilczek@gmail.com', 'stark.maciej@gmail.com', 'r.sporny@gmail.com','michal.kujawski@gmail.com']
  s.files       = Dir['lib/*.rb'] + Dir['lib/**/*.rb'] + Dir['bin/*']
  s.homepage    = 'https://github.com/bwilczek/moto'
  s.license     = 'MIT'
  s.executables << 'moto'
  s.required_ruby_version = '~> 2.0'
  s.add_runtime_dependency 'activesupport', '~> 5.0'
  s.add_runtime_dependency 'nokogiri', '~> 1.8'
  s.add_runtime_dependency 'rest-client', '~> 2.0'
end

