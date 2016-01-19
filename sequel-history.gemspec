Gem::Specification.new do |s|
  s.name        = 'sequel-history'
  s.version     = '0.1.0'
  s.date        = '2016-01-09'
  s.summary     = "A plugin for the Ruby ORM Sequel, that allows tracking changes on your models."
  s.description = "Use this plugin to mark a model instance as deleted without loosing its actual data."
  s.authors     = ["Fabian Becker"]
  s.email       = 'halfdan@xnorfz.de'
  s.files = Dir['Rakefile', '{lib,spec}/**/*', 'README*', 'LICENSE*', 'CHANGELOG*'] & `git ls-files -z`.split("\0")
  s.homepage    = 'https://github.com/halfdan/sequel-history'
  s.license     = "MIT"

  s.add_runtime_dependency "sequel"
  s.add_runtime_dependency "sequel-json"
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
end
