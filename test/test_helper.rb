require 'simplecov'
SimpleCov.start 'rails' do
 add_filter "/vendor/"
 add_filter "/test/"
 add_filter "/config/"
end

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActionController::TestCase
  include Devise::TestHelpers
end

require "mocha/setup"