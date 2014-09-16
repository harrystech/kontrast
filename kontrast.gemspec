# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kontrast/version'

Gem::Specification.new do |spec|
    spec.name          = "kontrast"
    spec.version       = Kontrast::VERSION
    spec.authors       = ["Ilya Rubnich"]
    spec.email         = ["ilya@harrys.com"]
    spec.summary       = %q{An automated testing tool for comparing visual differences between two versions of a website.}
    spec.homepage      = "https://github.com/harrystech/kontrast"
    spec.license       = "MIT"

    spec.files = Dir["{bin,lib,spec}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^spec/})
    spec.require_paths = ["lib"]

    spec.add_development_dependency "rake"
    spec.add_development_dependency "pry"
    spec.add_development_dependency "rspec"
    spec.add_dependency "bundler", "~> 1.6"
    spec.add_dependency "thor", "~> 0.19"
    spec.add_dependency "activesupport", "~> 4.1"
    spec.add_dependency "selenium-webdriver", "~> 2.43"
    spec.add_dependency "workers", "~> 0.2"
    spec.add_dependency "rmagick", "2.13.2"
    spec.add_dependency "fog", "~> 1.23"
end
