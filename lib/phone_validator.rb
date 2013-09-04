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

end
