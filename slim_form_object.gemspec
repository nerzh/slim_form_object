# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slim_form_object/version'

Gem::Specification.new do |spec|
  spec.name          = "slim_form_object"
  spec.version       = SlimFormObject::VERSION
  spec.authors       = ["woodcrust"]
  spec.email         = ["roboucrop@gmail.com"]

  spec.summary       = %q{This is form object}
  spec.description   = %q{Very simple automatic generation and saving nested attributes of models from html form. ActiveModel.}
  spec.homepage      = "https://github.com/woodcrust/slim_form_object"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*']
  spec.bindir        = "bin"
  spec.executables   = ["slim_form_object"]
  spec.require_paths = ["lib"]

  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  spec.add_runtime_dependency     "activemodel", ">= 5.0.0"
  spec.add_runtime_dependency     "actionview",  ">= 5.0.0"
  
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-collection_matchers", "~> 1.1"
  spec.add_development_dependency 'database_cleaner', '~> 1.5'
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency 'pg', '~> 0.18.4'
  spec.add_development_dependency 'byebug'
end
