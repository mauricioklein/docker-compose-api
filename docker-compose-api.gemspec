# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = "docker-compose-api"
  spec.version       = DockerCompose.version
  spec.authors       = ["Mauricio S. Klein"]
  spec.email         = ["mauricio.klein.msk@gmail.com"]
  spec.summary       = %q{A simple ruby client for docker-compose api}
  spec.description   = %q{A simple ruby client for docker-compose api}
  spec.homepage      = "https://github.com/mauricioklein/docker-compose-api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "docker-api", "~> 1.33"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "simplecov", "~> 0.10"
  spec.add_development_dependency "byebug", "~> 9.0"
end
