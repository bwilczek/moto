Gem::Specification.new do |s|
  s.name        = 'moto'
  s.version     = '0.0.3'
  s.date        = '2015-08-07'
  s.summary     = "Moto - yet another web testing framework"
  s.description = "This is a development version of a rails philosophy inspired framework for web applications functional testing. It supports (or will support) threading, scenario parametrization, different test environments and much more. Stay tuned for v.1.0.0 in the near future."
  s.authors     = ['Bartek Wilczek', 'Maciej Stark']
  s.email       = ['bwilczek@gmail.com', 'stark.maciej@gmail.com']
  s.files       = Dir['lib/*.rb'] + Dir['lib/**/*.rb'] + Dir['bin/*']
  s.homepage    =
    'https://github.com/bwilczek/moto'
  s.license       = 'MIT'
  s.executables << 'moto'
end