Gem::Specification.new do |s|
  s.name          = 'sequel-revisions'
  s.version       = '0.1.0'
  s.date          = '2016-01-19'
  s.summary       = "A plugin for the Ruby ORM Sequel, that allows tracking changes on your models."
  s.description   = "Use this plugin to track field changes and revert your model to an older state."
  s.authors       = ["Fabian Becker"]
  s.email         = 'halfdan@xnorfz.de'
  s.files         = ["lib/sequel/plugins/revisions.rb"]
  s.homepage      = 'https://github.com/halfdan/sequel-revisions'
  s.license       = "MIT"
  s.require_paths = ["lib"]

  s.add_runtime_dependency "sequel", '~> 4'
  s.add_runtime_dependency "sequel-json", '~> 0'
  s.add_development_dependency 'sqlite3', '~> 0'
  s.add_development_dependency 'rspec', '~> 0'
end
