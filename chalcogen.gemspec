# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chalcogen/version'

Gem::Specification.new do |spec|
    spec.name          = "chalcogen"
    spec.version       = WebDiff::VERSION
    spec.authors       = ["Ilya Rubnich"]
    spec.email         = ["ilya@harrys.com"]
    spec.summary       = %q{A website comparison tool.}
    #spec.description   = %q{TODO: Write a longer description. Optional.}
    spec.homepage      = ""
    spec.license       = "MIT"

    spec.files = Dir["{lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 1.6"
    spec.add_development_dependency "rake"
    spec.add_development_dependency "pry"
    spec.add_development_dependency "rspec"
    spec.add_dependency "activesupport"
    spec.add_dependency "selenium-webdriver"
    spec.add_dependency "rmagick", "2.13.2"
    spec.add_dependency "fog"
end
