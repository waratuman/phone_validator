require 'test_helper'

class Account
  include ActiveModel::Model

  attr_accessor :phone

  validates :phone, :phone => true
end

class PhoneValidatorTest < MiniTest::Unit::TestCase

  test 'validates phone number' do
    account = Account.new(:phone => 'invalid')
    assert !account.valid?
    assert account.errors[:phone]

    account = Account.new(:phone => '2342341234')
    assert account.valid?
  end

  test 'valid phone numbers' do
    account = Account.new

    numbers = (<<-EOF).split("\n").map(&:strip)
      2342355678
      234-235-5678
      (234)235-5678
      234.235.5678
      (234)-235-1234 x. 453
      (234)-235-2354 ex. 12345
      (234)-235-1234 ext. 453
      (234)-235-1234 extension 453
      +12342351234
      +1 234-235-1234
      1.234.235.1234
      12342351234
      1-234-235-1234
      1.234.235.1234
      +1 (234)-235-1234 x. 453
      +1 (234)-235-1234 ex. 12345
      +1 (234)-235-1234 ext. 453
      +1 (234)-235-1234 extension 453
    EOF

    numbers.each do |phone|
      account.phone = phone
      assert account.valid?
    end
  end

end
