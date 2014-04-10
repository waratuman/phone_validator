class PhoneValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if !value

    source = '\A((\+? ?1)([- \.]?))?((\( ?([2-9][0-8]\d) ?\))|([2-9][0-8]\d))([- \.]?)?([2-9]((0\d)|(1[02-9])|([2-9]\d)))([- \.]?)?(\d{4})'
    source = source + '( ?(x\.?| |\.|(ext\.?)|extension|ex\.?) ?(\d+))?' if options[:extension] != false
    source = source + '\z'

    unless value.strip =~ Regexp.compile(source, Regexp::IGNORECASE)
      record.errors.add(attribute, options[:message] || :invalid)
    end
    
  end
  
  def self.format_phone(number)
    return if !number || number.empty?
    number = number.gsub(/[^\d]/, '')
    number = '1' + number if number[0] != '1'
    number = '+' + number
    if !number[12..-1].to_s.empty?
      number = number[0..11] + 'x' + number[12..-1]
    end
    number
  end

end
