require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/reporters'
require 'active_support/testing/declarative'
require 'phone_validator'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Minitest::Test.extend ActiveSupport::Testing::Declarative
