require 'test_helper'

class Account
  include ActiveModel::Model

  attr_accessor :phone

  validates :phone, :phone => true
end

class Company
  include ActiveModel::Model

  attr_accessor :phone

  validates :phone, :phone => { :extension => false }
end

class PhoneValidatorTest < MiniTest::Test

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

  test 'extension option' do
    company = Company.new

    numbers = (<<-EOF).split("\n").map(&:strip)
      2342355678
      234-235-5678
      (234)235-5678
      234.235.5678
      +12342351234
      +1 234-235-1234
      1.234.235.1234
      12342351234
      1-234-235-1234
      1.234.235.1234
    EOF
    
    ext_numbers = (<<-EOF).split("\n").map(&:strip)
      (234)-235-1234 x. 453
      (234)-235-2354 ex. 12345
      (234)-235-1234 ext. 453
      (234)-235-1234 extension 453
      +1 (234)-235-1234 x. 453
      +1 (234)-235-1234 ex. 12345
      +1 (234)-235-1234 ext. 453
      +1 (234)-235-1234 extension 453
    EOF

    numbers.each do |phone|
      company.phone = phone
      assert company.valid?
    end

    ext_numbers.each do |phone|
      company.phone = phone
      assert !company.valid?
      assert company.errors[:phone]
    end
  end

  test 'format_phone' do
    # validation taken from http://zylstra.wordpress.com/2008/03/12/a-kinder-gentler-phone-number-validation/

    {
      '2342355678' => '+12342355678',
      '234-235-5678' => '+12342355678',
      '(234)235-5678' => '+12342355678',
      '234.235.5678' => '+12342355678',
      '(234)-235-1234 x. 453' => '+12342351234x453',
      '(234)-235-2354 ex. 12345' => '+12342352354x12345',
      '(234)-235-1234 ext. 453' => '+12342351234x453',
      '(234)-235-1234 extension 453' => '+12342351234x453',
      '+12342351234' => '+12342351234',
      '+1 234-235-1234' => '+12342351234',
      '1.234.235.1234' => '+12342351234',
      '12342351234' => '+12342351234',
      '1-234-235-1234' => '+12342351234',
      '1.234.235.1234' => '+12342351234',
      '+1 (234)-235-1234 x. 453' => '+12342351234x453',
      '+1 (234)-235-1234 ex. 12345' => '+12342351234x12345',
      '+1 (234)-235-1234 ext. 453' => '+12342351234x453',
      '+1 (234)-235-1234 extension 453' => '+12342351234x453'
    }.each do |from, to|
      assert_equal to, PhoneValidator.format_phone(from)
    end
  end

end
