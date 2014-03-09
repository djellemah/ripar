# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ripar/version'

Gem::Specification.new do |spec|
  spec.name          = "ripar"
  spec.version       = Ripar::VERSION
  spec.authors       = ["John Anderson"]
  spec.email         = ["panic@semiosix.com"]
  spec.summary       = %q{Chained methods cam be clunky. Use a block instead.}
  spec.description   = %q{Convert series of chained methods from . syntax to block syntax. Like instance_eval but with access to external scope.}
  spec.homepage      = "http://github.com/djellemah/ripar"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-debundle"
  spec.add_development_dependency "pry-debugger"
end
