# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)

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

  s.files       = Dir["lib/**/*.rb", "LICENSE"]
  s.executables = []
  s.test_files  = Dir["test/**/*"]

  s.add_development_dependency "minitest", "~> 5.10"
end
