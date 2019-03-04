# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'linchpin/version'

Gem::Specification.new do |spec|
  spec.name          = "linchpin"
  spec.version       = Linchpin::VERSION
  spec.authors       = ["Paul Everton"]
  spec.email         = ["Paul Everton"]
  spec.description   = "Linchpin will automatically figure out how to build and deploy your app!"
  spec.summary       = "Linchpin will automatically figure out how to build and deploy your app!"
  spec.homepage      = "https://github.com/DataConstruct/linchpin"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
end
