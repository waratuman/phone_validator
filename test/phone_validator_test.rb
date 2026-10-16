require 'test_helper'
require 'open3'

class PhoneValidatorTest < Minitest::Test

  VALID = {
    'US' => [
      '2342355678',
      '234-235-5678',
      '(234)235-5678',
      '(234) 235-5678',
      '234.235.5678',
      '234 235 5678',
      '+12342355678',
      '+1 234-235-5678',
      '+1 (234) 235-5678',
      '+1.234.235.5678',
      '12342355678',
      '1-234-235-5678',
      '1.234.235.5678',
      '212-555-1234',
      '416-967-1111',
      '+1 506 234 5678',
      '+44 20 7123 4567',
      '+44 7400 123456',
      '+49 30 123456',
      '+49 151 23456789',
      '+91 98765 43210',
      '+91 74104 10123',
      '+61 2 9876 5432',
      '+61 412 345 678',
      '011 44 20 7123 4567',
      "\n+12342355678\n",
      "234\u00A0235\u00A05678",
      "\uFF12\uFF13\uFF14\uFF12\uFF13\uFF15\uFF15\uFF16\uFF17\uFF18",
      '787-281-1234',
      '876-927-1234',
      '310-1234',
      '(+1) 234-235-5678',
      '(+44) 20 7123 4567',
      "234\u2013235\u20135678",
      "\u202A+1 (234) 235-5678\u202C",
      "\u200E+44 20 7123 4567",
      "\u2068(234) 235-5678\u2069"
    ],
    'CA' => ['416 967 1111', '234 235 5678'],
    'GB' => ['020 7123 4567', '07400 123456', '01252 415900', '+44 01252 415900', '+44 (01252) 415900', '+1 234 235 5678', '01481 712345'],
    'DE' => ['030 123456', '0151 23456789'],
    'IN' => ['098765 43210', '98765 43210'],
    'AU' => ['(02) 9876 5432', '0412 345 678']
  }

  INVALID = {
    'US' => [
      'invalid',
      '12345',
      '235-5678',
      '23423556789',
      '234-235-56789',
      '+1 234 235 5678 9',
      '211-234-5678',
      '411-234-5678',
      '911-234-5678',
      '023-235-5678',
      '123-235-5678',
      '212-555-0100',
      '212-555-0123',
      '201-555-0199',
      '+1 416 555 0100',
      '234-235-5678 call me',
      '1-800-FLOWERS',
      '234-235-5678 x',
      '234-235-5678+',
      '2+3+4-235-5678',
      "234 235\n5678",
      "234\v235\f5678",
      "234-235-5678\x00",
      "\x00234-235-5678",
      "\u00B2\u00B3\u2074 \u00B2\u00B3\u2075 \u2075\u2076\u2077\u2078",
      '1' * 251,
      '911',
      '442071234567',
      '02071234567',
      '+44 20 7123 456',
      '+44 20 7123 45678',
      '+49 30 12',
      '+91 98765 4321',
      '+61 412 345 67'
    ],
    'GB' => ['020 7123 456', '00000 000000'],
    'DE' => ['0151 234'],
    'AU' => ['0412 345 6789']
  }

  def model(**options)
    Class.new do
      include ActiveModel::Model

      attr_accessor :phone

      validates :phone, phone: options.empty? ? true : options

      def self.name
        'Contact'
      end
    end
  end

  def assert_valid_phone(number, **options)
    record = model(**options).new(phone: number)
    assert record.valid?, "Expected #{number.inspect} to be valid with #{options.inspect}"
  end

  def assert_invalid_phone(number, **options)
    record = model(**options).new(phone: number)
    assert !record.valid?, "Expected #{number.inspect} to be invalid with #{options.inspect}"
    assert_equal [{ error: :invalid, value: number }], record.errors.details[:phone]
  end

  test 'valid numbers' do
    VALID.each do |country, numbers|
      numbers.each { |number| assert_valid_phone(number, default_country: country) }
    end
  end

  test 'invalid numbers' do
    INVALID.each do |country, numbers|
      numbers.each { |number| assert_invalid_phone(number, default_country: country) }
    end
  end

  test 'default country is US' do
    assert_valid_phone '234-235-5678'
    assert_invalid_phone '020 7123 4567'
  end

  test 'default country accepts symbols and lowercase' do
    assert_valid_phone '020 7123 4567', default_country: :gb
    assert_valid_phone '020 7123 4567', default_country: 'gb'
  end

  test 'mobile option' do
    [
      '234-235-5678',
      '416-967-1111',
      '+44 7400 123456',
      '+49 151 23456789',
      '+91 98765 43210',
      '+91 74104 10123',
      '+61 412 345 678'
    ].each { |number| assert_valid_phone(number, mobile: true) }

    [
      '800-234-5678',
      '888-234-5678',
      '900-234-5678',
      '+44 20 7123 4567',
      '+44 800 123 4567',
      '+44 901 234 5678',
      '+49 30 123456',
      '+49 800 1234567890',
      '+61 2 9876 5432',
      '+61 1800 123 456',
      '+61 1900 123 456'
    ].each { |number| assert_invalid_phone(number, mobile: true) }
  end

  test 'toll-free and premium-rate numbers are valid without a type restriction' do
    assert_valid_phone '800-234-5678'
    assert_valid_phone '900-234-5678'
    assert_valid_phone '+44 800 123 4567'
  end

  test 'types option' do
    assert_valid_phone '800-234-5678', types: :toll_free
    assert_invalid_phone '234-235-5678', types: :toll_free
    assert_valid_phone '234-235-5678', types: [:fixed_line]
    assert_valid_phone '+44 20 7123 4567', types: [:fixed_line]
    assert_invalid_phone '+44 7400 123456', types: [:fixed_line]
    assert_valid_phone '800-234-5678', types: [:toll_free], mobile: true
    assert_valid_phone '+44 7400 123456', types: [:toll_free], mobile: true
    assert_invalid_phone '+44 20 7123 4567', types: [:toll_free], mobile: true
  end

  test 'fixed_or_mobile type accepts fixed lines and mobiles' do
    assert_valid_phone '234-235-5678', types: [:fixed_or_mobile]
    assert_valid_phone '+44 7400 123456', types: [:fixed_or_mobile]
    assert_valid_phone '+44 20 7123 4567', types: [:fixed_or_mobile]
    assert_invalid_phone '800-234-5678', types: [:fixed_or_mobile]
  end

  test 'unknown types raise' do
    error = assert_raises(ArgumentError) { model(types: [:cell]) }
    assert_equal 'Unknown phone types: :cell', error.message

    error = assert_raises(ArgumentError) { model(types: ['mobile', nil]) }
    assert_equal 'Unknown phone types: :""', error.message

    error = assert_raises(ArgumentError) { model(types: [:short_code]) }
    assert_equal 'Unknown phone types: :short_code', error.message
  end

  test 'unknown countries raise' do
    error = assert_raises(ArgumentError) { model(default_country: 'UK') }
    assert_equal 'Unknown country: "UK"', error.message

    error = assert_raises(ArgumentError) { model(default_country: nil) }
    assert_equal 'Unknown country: nil', error.message

    error = assert_raises(ArgumentError) { model(countries: ['US', 'XX']) }
    assert_equal 'Unknown country: "XX"', error.message

    error = assert_raises(ArgumentError) { PhoneValidator.normalize('020 7123 4567', default_country: 'UK') }
    assert_equal 'Unknown country: "UK"', error.message

    assert_raises(ArgumentError) { PhoneValidator.parse('020 7123 4567', default_country: 'XX') }
  end

  test 'empty countries and types raise' do
    error = assert_raises(ArgumentError) { model(countries: []) }
    assert_equal 'countries must not be empty', error.message

    error = assert_raises(ArgumentError) { model(types: []) }
    assert_equal 'types must not be empty', error.message
  end

  test 'unknown options raise' do
    %i[possible extensions country_specifier format require_international_prefix detailed_errors country].each do |option|
      error = assert_raises(ArgumentError) { model(option => true) }
      assert_equal "Unknown options: #{option.inspect}", error.message
    end
  end

  test 'countries option' do
    assert_valid_phone '234-235-5678', countries: ['US', 'CA']
    assert_valid_phone '416-967-1111', countries: ['US', 'CA']
    assert_invalid_phone '+44 20 7123 4567', countries: ['US', 'CA']
    assert_valid_phone '+44 20 7123 4567', countries: :gb
    assert_invalid_phone '416-967-1111', countries: 'US'
    assert_valid_phone '1-800-234-5678', countries: ['CA']
    assert_invalid_phone '787-281-1234', countries: ['US']
    assert_invalid_phone '01481 712345', default_country: 'GB', countries: ['GB']
  end

  test 'numbers from countries sharing the default calling code' do
    assert_equal 'CA', PhoneValidator.parse('416-967-1111').country
    assert_equal 'PR', PhoneValidator.parse('787-281-1234').country
    assert_equal 'JM', PhoneValidator.parse('876-927-1234').country
    assert_equal 'GG', PhoneValidator.parse('01481 712345', default_country: 'GB').country
  end

  test 'ignores phonelib global settings' do
    settings = %i[parse_special strict_check sanitize_regex extension_separate_symbols]
    original = settings.to_h { |setting| [setting, Phonelib.public_send(setting)] }

    Phonelib.parse_special = true
    Phonelib.strict_check = true
    Phonelib.sanitize_regex = '[\\.\\-\\(\\) \\;\\+]'
    Phonelib.extension_separate_symbols = '/'

    assert_nil PhoneValidator.normalize('911')
    assert_nil PhoneValidator.normalize('999')
    assert_nil PhoneValidator.normalize('112', default_country: 'GB')
    assert_nil PhoneValidator.normalize('1101', default_country: 'AU')
    assert_nil PhoneValidator.normalize('1140', default_country: 'CH')
    assert_nil PhoneValidator.normalize('1030', default_country: 'IN')
    assert_nil PhoneValidator.normalize('+61 1903 136')
    assert_nil PhoneValidator.normalize('34568', default_country: 'ZW')
    assert_nil PhoneValidator.normalize('80847', default_country: 'DE')
    assert_equal '+12342355678', PhoneValidator.normalize('(234) 235-5678')
    assert_equal '+12342355678', PhoneValidator.normalize('234/235/5678')
    assert_equal '+442071234567', PhoneValidator.normalize('+44 20 7123 4567')
    assert_nil PhoneValidator.normalize('2342355678/999')
    assert_invalid_phone '911'
  ensure
    original&.each { |setting, value| Phonelib.public_send(:"#{setting}=", value) }
  end

  test 'input that is not ASCII-compatible text' do
    assert_nil PhoneValidator.normalize("234-235-5678\xFF")
    assert_nil PhoneValidator.normalize('234-235-5678'.encode('UTF-16LE'))
    assert_equal '+12342355678', PhoneValidator.normalize('234-235-5678'.b)
    assert_equal '+12342355678', PhoneValidator.normalize("234\u2013235\u20135678".b)
    assert_nil PhoneValidator.normalize("234-235-5678\xFF".b)
    assert_nil PhoneValidator.normalize("234\x81235-5678".force_encoding('Windows-1252'))
    assert_nil PhoneValidator.normalize("234-235-5678\xFF".force_encoding('Windows-1258'))
  end

  test 'long input is rejected quickly' do
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    assert_nil PhoneValidator.parse('9' * 5_000_000)
    assert_nil PhoneValidator.parse('1 ' * 500_000)
    assert_nil PhoneValidator.parse("\u00A0" * 5_000_000)
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.5
  end

  test 'extension option' do
    numbers = [
      '(234)-235-1234 x. 453',
      '(234)-235-2354 ex. 12345',
      '(234)-235-1234 ext. 453',
      '(234)-235-1234 extension 453',
      '(234)-235-1234 EXT 453',
      '(234)-235-1234#453',
      '(234)-235-1234;453',
      '+1 (234)-235-1234 x453',
      '+44 20 7123 4567 x 453',
      '+44 20 7123 4567 X 453',
      '+442071234567 EXTENSION 4323'
    ]

    numbers.each do |number|
      assert_invalid_phone number
      assert_invalid_phone number, extension: false
      assert_valid_phone number, extension: true
    end

    assert_invalid_phone '(211)-235-1234 x 453', extension: true
  end

  test 'blank values are invalid by default' do
    [nil, '', '   '].each { |value| assert_invalid_phone value }
  end

  test 'allow_blank and allow_nil' do
    [nil, '', '   '].each { |value| assert_valid_phone value, allow_blank: true }
    assert_valid_phone nil, allow_nil: true
    assert_invalid_phone '', allow_nil: true
    assert_invalid_phone 'invalid', allow_blank: true
  end

  test 'ActiveModel options are accepted' do
    model = Class.new do
      include ActiveModel::Model
      attr_accessor :phone
      validates_with PhoneValidator, attributes: [:phone], prepend: true, on: :create, if: -> { true }
      def self.name = 'Contact'
    end
    assert !model.new(phone: 'invalid').valid?(:create)
  end

  test 'message option' do
    record = model(message: 'is not a phone number').new(phone: 'invalid')
    assert !record.valid?
    assert_equal ['Phone is not a phone number'], record.errors.full_messages
  end

  test 'default message' do
    record = model.new(phone: 'invalid')
    assert !record.valid?
    assert_equal ['Phone is invalid'], record.errors.full_messages
  end

  test 'strict option' do
    assert_raises(ActiveModel::StrictValidationFailed) { model(strict: true).new(phone: 'invalid').valid? }
  end

  test 'non-string values' do
    assert_valid_phone 2342355678
    assert_invalid_phone 12345
  end

  test 'normalize' do
    {
      '2342355678' => '+12342355678',
      '234-235-5678' => '+12342355678',
      '(234)235-5678' => '+12342355678',
      '234.235.5678' => '+12342355678',
      '(234)-235-1234 x. 453' => '+12342351234',
      '(234)-235-2354 ex. 12345' => '+12342352354',
      '(234)-235-1234 ext. 453' => '+12342351234',
      '(234)-235-1234 extension 453' => '+12342351234',
      '+12342351234' => '+12342351234',
      '+1 234-235-1234' => '+12342351234',
      '1.234.235.1234' => '+12342351234',
      '12342351234' => '+12342351234',
      '1-234-235-1234' => '+12342351234',
      '+1.234.235.1234' => '+12342351234',
      '+1 (234)-235-1234 ext. 453' => '+12342351234',
      '416-967-1111' => '+14169671111',
      '+44 1252 415900' => '+441252415900',
      '+441252415900' => '+441252415900',
      '+44-1252-415900' => '+441252415900',
      '+44 01252 415900' => '+441252415900',
      '+44 (01252) 415900' => '+441252415900',
      '+44 1252 415900 ext 545' => '+441252415900',
      '+49 151 23456789' => '+4915123456789',
      '+91 98765 43210' => '+919876543210',
      '+61 412 345 678' => '+61412345678'
    }.each do |from, to|
      assert_equal to, PhoneValidator.normalize(from)
    end

    assert_nil PhoneValidator.normalize(nil)
    assert_nil PhoneValidator.normalize('')
    assert_nil PhoneValidator.normalize('invalid')
    assert_nil PhoneValidator.normalize('212-555-0123')
    assert_nil PhoneValidator.normalize('020 7123 4567')
  end

  test 'normalize with default country' do
    assert_equal '+442071234567', PhoneValidator.normalize('020 7123 4567', default_country: 'GB')
    assert_equal '+4915123456789', PhoneValidator.normalize('0151 23456789', default_country: :de)
    assert_equal '+61412345678', PhoneValidator.normalize('0412 345 678', default_country: 'AU')
    assert_equal '+919876543210', PhoneValidator.normalize('098765 43210', default_country: 'IN')
    assert_equal '+12342355678', PhoneValidator.normalize('+1 234 235 5678', default_country: 'GB')
  end

  test 'parse' do
    result = PhoneValidator.parse('(234) 235-5678 ext. 99')
    assert_equal '+12342355678', result.e164
    assert_equal '99', result.extension
    assert_equal 'US', result.country
    assert_equal :fixed_or_mobile, result.type
    assert_equal '(234) 235-5678', result.national
    assert_equal '+1 234-235-5678', result.international

    result = PhoneValidator.parse('07400 123456', default_country: 'GB')
    assert_equal '+447400123456', result.e164
    assert_nil result.extension
    assert_equal 'GB', result.country
    assert_equal :mobile, result.type
    assert_equal '07400 123456', result.national
    assert_equal '+44 7400 123456', result.international

    assert_equal 'CA', PhoneValidator.parse('416-967-1111').country
    assert_equal :toll_free, PhoneValidator.parse('800-234-5678').type
    assert_equal :premium_rate, PhoneValidator.parse('900-234-5678').type

    assert_nil PhoneValidator.parse(nil)
    assert_nil PhoneValidator.parse('')
    assert_nil PhoneValidator.parse('invalid')
  end

  test 'frozen strings' do
    number = '(234) 235-5678 x 12'.freeze
    assert_equal '+12342355678', PhoneValidator.normalize(number)
    assert_equal '12', PhoneValidator.parse(number).extension
    assert_valid_phone number, extension: true
    assert_equal '(234) 235-5678 x 12', number
  end

  test 'does not mutate input' do
    number = +'+44 01252 415900 x 12'
    PhoneValidator.normalize(number)
    assert_valid_phone number, default_country: 'GB', extension: true
    assert_equal '+44 01252 415900 x 12', number
  end

  # This file has no frozen_string_literal comment, so literals are chilled on
  # Ruby 3.4+ and mutating one emits a deprecation warning.
  test 'chilled strings' do
    deprecated = Warning[:deprecated]
    Warning[:deprecated] = true
    assert_output(nil, '') do
      PhoneValidator.normalize('(234) 235-5678 x 12')
      assert_valid_phone '(234) 235-5678 x 12', extension: true
    end
  ensure
    Warning[:deprecated] = deprecated
  end

  # Each script loads phonelib's validator at a different point, then checks
  # that this gem's validator is the one in use.
  test 'replaces the validator bundled with phonelib in any load order' do
    check = <<~RUBY
      model = Class.new do
        include ActiveModel::Model
        attr_accessor :phone
        validates :phone, phone: true
        def self.name = 'Contact'
      end
      exit(model.new(phone: '+1 234-235-5678 call me').valid? || PhoneValidator.include?(Phonelib::Core) ? 1 : 0)
    RUBY

    [
      "require 'phone_validator'; require 'validators/phone_validator'",
      "require 'active_model'; require 'phonelib'; PhoneValidator; require 'phone_validator'",
      <<~RUBY
        require 'active_model'; require 'phonelib'
        legacy = Class.new { include ActiveModel::Model; attr_accessor :phone; validates :phone, phone: true; def self.name = 'Legacy' }
        require 'phone_validator'
        legacy.new(phone: '2342355678').valid?
      RUBY
    ].each do |setup|
      output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', '-rbundler/setup', '-e', "#{setup}\n#{check}")
      assert status.success?, "#{setup}\n#{output}"
    end
  end

end
