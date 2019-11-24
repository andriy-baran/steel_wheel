lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "steel_wheel/version"

Gem::Specification.new do |spec|
  spec.name          = "steel_wheel"
  spec.version       = SteelWheel::VERSION
  spec.authors       = ["Andrii Baran"]
  spec.email         = ["andriy.baran.v@gmail.com"]

  spec.summary       = %q{Adds operations to your rails code}
  spec.description   = %Q{Tiny DSL for code in controllers}
  spec.homepage      = 'https://github.com/andriy-baran/steel_wheel'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/andriy-baran/steel_wheel'
    # spec.metadata['changelog_uri'] = 'TODO: Put your gem's CHANGELOG.md URL here.'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.2'

  version_string = ['>= 3.0']

  spec.add_runtime_dependency 'activemodel', version_string
  spec.add_runtime_dependency 'railties', version_string

  spec.add_dependency 'dry-types', '~> 0.13.4'
  spec.add_dependency 'dry-logic', '~> 0.4.2'
  spec.add_dependency 'dry-struct'
  spec.add_dependency 'memery'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec_vars_helper'
end
