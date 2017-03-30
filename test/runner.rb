require "step_track"
require "minitest/spec"
require "minitest/autorun"

Dir["**/*_test.rb"].shuffle.each { |f| load f }
