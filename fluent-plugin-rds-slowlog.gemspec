# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-rds-slowlog"
  gem.version       = "0.0.8"
  gem.authors       = ["kenjiskywalker", "winebarrel"]
  gem.email         = ["git@kenjiskywalker.org", "sgwr_dts@yahoo.co.jp"]
  gem.description   = "Amazon RDS slow_log input plugin for Fluent event collector"
  gem.homepage      = "https://github.com/kenjiskywalker/fluent-plugin-rds-slowlog"
  gem.summary       = gem.description
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "fluentd", [">= 0.14.0", "< 2"]
  gem.add_development_dependency "rake", ">= 10.0.4"

  gem.add_dependency "mysql2",  "~> 0.3.11"
  gem.add_development_dependency "test-unit", "~> 3.1.3"
  gem.add_development_dependency "timecop"
end
