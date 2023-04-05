# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "step_track/version"

Gem::Specification.new do |s|
  s.name        = "step-track"
  s.version     = StepTrack::VERSION

  s.summary     = "Tracks data fragments across the application"
  s.description = "Stores data fragments as steps for an executing trail"
  s.authors     = ["Matthias Geier"]
  s.email       = "mayutamano@gmail.com "
  s.homepage    = "https://github.com/matthias-geier/track_step"
  s.license     = "BSD-2-Clause"

  s.required_ruby_version = Gem::Requirement.new(">= 2.6.1")
  s.metadata["allowed_push_host"] = "https://gemserver.metoda.com"

  s.files       = Dir["lib/**/*.rb", "LICENSE"]
  s.executables = []

  s.add_development_dependency "geminabox"
  s.add_development_dependency "minitest", "~> 5.10"
  s.add_development_dependency "rubocop", "~> 1.0"
  s.add_development_dependency "rubocop-minitest", "~> 0.29"
end
