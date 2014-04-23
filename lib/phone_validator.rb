require 'phony'

class PhoneValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if !value
    test_value = value

    if options[:extension]
      test_value = test_value.gsub(/( ?(x\.?|(ext\.?)|extension|ex\.?) ?(\d+))/, '')
    end

    test_value = "+1#{test_value}" if !Phony.plausible?(test_value)

    if !Phony.plausible?(test_value)
      record.errors.add(attribute, options[:message] || :invalid)
    end
  end
  
  def self.normalize(number, options={})
    return if !number || number.empty?

    extension = nil
    if options[:extension]
      number =~ /( ?(x\.?|(ext\.?)|extension|ex\.?) ?(\d+))/
      extension = $4
      number = number.gsub(/( ?(x\.?|(ext\.?)|extension|ex\.?) ?(\d+))/, '')
    end

    number = "+1" + number if !Phony.plausible?(number)

    return if !Phony.plausible?(number)

    if options[:extension] && extension
      Phony.normalize(number) + 'x' + extension
    else
      Phony.normalize(number)
    end
  end

end
