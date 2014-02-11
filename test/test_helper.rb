ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/pride"
require "minitest/reporters"
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

class ActiveSupport::TestCase
  fixtures :all
end
