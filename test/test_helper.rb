require 'rubygems'
require 'bundler/setup'
require 'active_model'
require 'minitest/autorun'
require 'minitest/reporters'
require 'phone_validator'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class Module
  
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9']/i, "_")}".to_sym, &block)
  end

end