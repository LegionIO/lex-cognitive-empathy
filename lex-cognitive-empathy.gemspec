# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_empathy/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-empathy'
  spec.version       = Legion::Extensions::CognitiveEmpathy::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Cognitive empathy engine for LegionIO'
  spec.description   = 'Perspective-taking, emotional contagion modeling, and empathic accuracy ' \
                       'tracking for LegionIO agentic extensions'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-empathy'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']   = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
