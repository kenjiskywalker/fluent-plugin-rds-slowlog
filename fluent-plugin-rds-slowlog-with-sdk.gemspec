# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-rds-slowlog-with-sdk"
  gem.version       = "0.0.5"
  gem.authors       = ["ando-masaki"]
  gem.email         = ["ando_masaki@ando-masaki.com"]
  gem.description   = "Amazon RDS slow_log input plugin for Fluent event collector with AWS SDK for Ruby"
  gem.homepage      = "https://github.com/ando-masaki/fluent-plugin-rds-slowlog-with-sdk"
  gem.summary       = gem.description
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "fluentd", "~> 0.10.30"
  gem.add_dependency "aws-sdk", "~> 1.8.5"
  gem.add_dependency "myslog",  "~> 0.0.10"
  gem.add_development_dependency "rake", ">= 10.0.4"
end
