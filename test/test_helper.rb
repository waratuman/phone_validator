require 'rubygems'
require 'bundler/setup'
require 'active_model'
require 'minitest/unit'
require 'turn/autorun'
require 'phone_validator'

class Module
  
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9']/i, "_")}".to_sym, &block)
  end

end