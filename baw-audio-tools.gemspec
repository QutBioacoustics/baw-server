# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baw-audio-tools/version'
require 'rbconfig'

Gem::Specification.new do |spec|
  spec.name          = 'baw-audio-tools'
  spec.version       = BawAudioTools::VERSION
  spec.authors       = ['Mark Cottman-Fields']
  spec.email         = ['qut.bioacoustics.research+mark@gmail.com']
  spec.summary       = %q{Bioacoustics Workbench audio tools}
  spec.description   = %q{Contains the audio, spectrogram, and caching tools for the Bioacoustics Workbench project.}
  spec.homepage      = 'https://github.com/QutBioacoustics/baw-audio-tools'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # dev dependencies
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.4.2'
  spec.add_development_dependency 'guard', '~> 2.11.1'
  spec.add_development_dependency 'guard-rspec', '~> 4.5.0'
  spec.add_development_dependency 'guard-yard', '~> 2.1.1'
  spec.add_development_dependency 'simplecov', '~> 0.9.0'
  spec.add_development_dependency 'coveralls', '~> 0.7.0'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'zonebie'
  spec.add_development_dependency 'i18n'
  spec.add_development_dependency 'tzinfo', '~> 1.2.2'

  # runtime dependencies
  spec.add_runtime_dependency 'activesupport', '>= 3.2'

end
