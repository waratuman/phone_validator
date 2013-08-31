class PhoneValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if !value
    unless value =~ /\A((\+? ?1)([- \.]?))?((\( ?([2-9][0-8]\d) ?\))|([2-9][0-8]\d))([- \.]?)?([2-9]((0\d)|(1[02-9])|([2-9]\d)))([- \.]?)?(\d{4})( ?(x\.?| |\.|(ext\.?)|extension|ex\.?) ?(\d+))?\z/i
      record.errors.add(attribute, options[:message] || :invalid)
    end
    
  end

end
