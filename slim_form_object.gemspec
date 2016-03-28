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
  spec.description   = %q{It's works}
  spec.homepage      = "http://inclouds.com.ua"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end


  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.

  spec.files         = Dir['lib/**/*']
  spec.bindir        = "bin"
  spec.executables   = ["slim_form_object"]
  spec.require_paths = ["lib"]

  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activemodel", "~> 4.2"
end
