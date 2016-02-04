$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'ncmec_reporting/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'ncmec_reporting'
  s.version     = NcmecReporting::VERSION
  s.authors     = ['jejacks0n', 'mikepack']
  s.email       = ['info@ello.co']
  s.homepage    = 'https://github.com/ello/ncmec_reporting'

  s.summary     = "Wrapper around NCMEC API"
  s.description = "Provides an OO abstraction around the API"
  s.files       = Dir["{lib}/**/*"] + ["README.md"]
  # Not including test files as VCR file names are too long.
  # s.test_files  = `git ls-files -- {spec}/*`.split("\n")

  s.add_dependency 'fog-aws'
  s.add_dependency 'net-ssh'
  s.add_dependency 'aasm'
  s.add_dependency 'nokogiri'
  s.add_dependency 'builder'
  s.add_dependency 'typhoeus'
  s.add_dependency 'faraday'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'dotenv'
end
