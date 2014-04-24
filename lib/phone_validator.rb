require 'phony'

class PhoneValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if !value
    test_value = PhoneValidator.normalize(value, extension: false)

    if !Phony.plausible?(test_value)
      record.errors.add(attribute, options[:message] || :invalid)
    end

    # If there is an extension, but shouldn't be
    if !options[:extension] && test_value != PhoneValidator.normalize(value, extension: true)
      record.errors.add(attribute, options[:message] || :invalid)
    end

  end
  
  def self.normalize(number, options={})
    return if !number || number.empty?

    extension = nil

    number =~ /( ?(x\.?|(ext\.?)|extension|ex\.?) ?(\d+))/
    extension = $4
    number = number.gsub(/( ?(x\.?|(ext\.?)|extension|ex\.?) ?(\d+))/, '').gsub(/[^\d\+]/, '')

    number = "+1" + number if number[0] != '+' && number.length == 10

    return if !Phony.plausible?(number)

    if options[:extension] != false && extension
      '+' + Phony.normalize(number) + 'x' + extension
    else
      '+' + Phony.normalize(number)
    end
  end

end
