$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "pier_logging"

require "minitest/autorun"
require 'mocha/minitest'
require 'shoulda'
require 'byebug'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
  end
end
