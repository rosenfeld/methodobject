# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'method_object/version'

Gem::Specification.new do |spec|
  spec.name          = "methodobject"
  spec.version       = MethodObject::VERSION
  spec.authors       = ["Michele Piccirillo"]
  spec.email         = ["michele@liqid.de"]

  spec.summary       = 'Method Object pattern in Ruby for your service objects'
  spec.description   = <<-EOF
    Lightweight and dependency-free solution for the creation of method objects,
    a common pattern used to ease the extraction of complex methods from other classes
    and for the implementation of service objects.
  EOF

  spec.homepage      = "https://github.com/LIQIDTechnology/methodobject"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "coveralls"
end
