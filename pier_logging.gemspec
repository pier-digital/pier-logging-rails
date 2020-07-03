
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pier_logging/version"

Gem::Specification.new do |spec|
  spec.name          = "pier_logging"
  spec.version       = PierLogging::VERSION
  spec.authors       = ["Mauricio Banduk"]
  spec.email         = ["mauricio.banduk@pier.digital"]

  spec.summary       = %q{Structured log used on Pier Applications}
  spec.description   = %q{Defines a basic structure for general and request logging}
  spec.homepage      = "https://github.com/pier-digital"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ougai"
  spec.add_dependency "awesome_print"
  spec.add_dependency "rails"
  spec.add_dependency "facets"

  spec.add_development_dependency "bundler", ">= 2.1.4"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "minitest", ">= 5.8.4"
  spec.add_development_dependency "byebug", ">= 11.1.3"
end
