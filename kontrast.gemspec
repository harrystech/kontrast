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
    spec.description   = %q{Kontrast is a testing tool that lets you build a frontend test suite to run against your test and production websites. It uses Selenium to take screenshots and ImageMagick to compare them. Kontrast then produces a detailed gallery of its test results.}
    spec.homepage      = "https://github.com/harrystech/kontrast"
    spec.license       = "MIT"

    spec.files = Dir["{bin,lib,spec}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^spec/})
    spec.require_paths = ["lib"]

    spec.add_development_dependency "rake", "~> 10.0"
    spec.add_development_dependency "pry", "~> 0.10"
    spec.add_development_dependency "rspec", "~> 3.0"
    spec.add_dependency "bundler", "~> 1.6"
    spec.add_dependency "thor", "~> 0.0"
    spec.add_dependency "selenium-webdriver", "~> 2.0"
    spec.add_dependency "workers", "~> 0.2"
    spec.add_dependency "rmagick", "2.16.0"
    spec.add_dependency "fog-aws", "~> 0.9"
    spec.add_dependency "faraday", "~> 0.9"
    spec.add_dependency "rack", ">= 0.4"
end
