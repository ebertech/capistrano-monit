# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano-monit/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Andrew Eberbach"]
  gem.email         = ["andrew@ebertech.ca"]
  gem.description   = %q{Monit deployment helper}
  gem.summary       = %q{Monit deployment helper}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-monit"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Monit::VERSION
end
