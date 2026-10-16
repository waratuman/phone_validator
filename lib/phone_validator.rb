# frozen_string_literal: true

require 'active_model'
require 'phonelib'

# phonelib ships a validator under this name. Drop its pending autoload (or the
# class, if something already loaded it) so this class is defined from scratch,
# and mark its file as loaded so a later require can't reopen this class.
if Object.autoload?(:PhoneValidator) == 'validators/phone_validator' ||
   (!Object.autoload?(:PhoneValidator) && Object.const_defined?(:PhoneValidator, false) &&
    PhoneValidator.include?(Phonelib::Core))
  Object.send(:remove_const, :PhoneValidator)
end
if (phonelib_spec = Gem.loaded_specs['phonelib']) &&
   (phonelib_validator = $LOAD_PATH.resolve_feature_path('validators/phone_validator')&.last) &&
   phonelib_validator.start_with?(phonelib_spec.full_gem_path) &&
   !$LOADED_FEATURES.include?(phonelib_validator)
  $LOADED_FEATURES << phonelib_validator
end

class PhoneValidator < ActiveModel::EachValidator

  Result = Data.define(:e164, :extension, :country, :type, :national, :international)

  DEFAULT_COUNTRY = 'US'

  # libphonenumber rejects longer input too.
  MAX_LENGTH = 250

  EXTENSION = / *(?:extension|ext\.?|ex\.?|x\.?|#|;) *(\d+)\z/i

  NUMBER = %r{\A\(?\+?[\d ()\-./]+\z}

  CONTROL_CHARACTERS = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/

  # Characters phones and word processors put in pasted numbers.
  UNICODE_SPACES = /[\u00A0\u2000-\u200A\u202F\u205F\u3000]/
  UNICODE_DASHES = /[\u2010-\u2015\u2212]/
  INVISIBLE_CHARACTERS = "\u00AD\u061C\u200B-\u200F\u202A-\u202E\u2060\u2066-\u2069\uFEFF"

  # 555-0100 through 555-0199 are reserved for fiction in every NANP area code.
  FICTIONAL_NANP = /\A\+1\d{3}55501\d{2}\z/

  # The types libphonenumber assigns to dialable numbers.
  TYPES = %i[
    fixed_line mobile fixed_or_mobile toll_free premium_rate shared_cost voip
    personal_number pager uan voicemail
  ].freeze

  # Countries such as the US don't distinguish fixed lines from mobiles.
  FIXED_LINE_AND_MOBILE = %i[fixed_line mobile].freeze

  OPTIONS = %i[default_country countries types mobile extension].freeze

  ACTIVE_MODEL_OPTIONS = %i[message if unless on except_on prepend allow_nil allow_blank strict].freeze

  def self.parse(input, default_country: DEFAULT_COUNTRY)
    phone, extension = analyze(input, default_country)
    return unless phone

    Result.new(
      e164: phone.e164,
      extension: extension,
      country: phone.country,
      type: phone.type,
      national: phone.national,
      international: phone.international
    )
  end

  def self.normalize(input, default_country: DEFAULT_COUNTRY)
    analyze(input, default_country)&.first&.e164
  end

  # Returns the valid Phonelib::Phone and the extension, or nil.
  def self.analyze(input, default_country)
    country = country_code(default_country)
    number = input.to_s
    return if number.bytesize > MAX_LENGTH * 4
    return unless number.valid_encoding? && number.encoding.ascii_compatible?
    return if CONTROL_CHARACTERS.match?(number)

    unless number.ascii_only?
      number = number.dup.force_encoding(Encoding::UTF_8) if number.encoding == Encoding::BINARY
      begin
        number = number.encode(Encoding::UTF_8)
      rescue EncodingError
        return
      end
      return unless number.valid_encoding?

      number = number.tr("\uFF01-\uFF5E", '!-~')
                     .gsub(UNICODE_SPACES, ' ')
                     .gsub(UNICODE_DASHES, '-')
                     .delete(INVISIBLE_CHARACTERS)
    end
    number = number.strip
    return if number.length > MAX_LENGTH

    extension = number[EXTENSION, 1]
    number = number.sub(EXTENSION, '')
    return unless NUMBER.match?(number)

    # Pass phonelib digits only, so its global sanitize_regex, strict_check and
    # extension_separate_symbols settings can't change the result.
    digits = number.delete('^0-9')
    digits = "+#{digits}" if number.match?(/\A\(?\+/)

    phone = parse_phone(digits, country)
    return unless phone.valid?
    # With Phonelib.parse_special on, phonelib also matches short codes and
    # emergency numbers, sometimes under ordinary types like :toll_free.
    national = phone.e164.delete_prefix("+#{Phonelib.phone_data.dig(phone.country, :country_code)}")
    return unless type_patterns[phone.country]&.any? { |pattern| pattern.match?(national) }
    return if FICTIONAL_NANP.match?(phone.e164)

    [phone, extension]
  end
  private_class_method :analyze

  def self.country_code(country)
    code = country.to_s.upcase
    raise ArgumentError, "Unknown country: #{country.inspect}" unless Phonelib.phone_data.key?(code)

    code
  end
  private_class_method :country_code

  # Phonelib only tries the default country for national numbers, so with a
  # US default a Canadian number is invalid. Retry with the other countries
  # that share the default's calling code and whose leading digits match.
  def self.parse_phone(number, country)
    phone = Phonelib.parse(number, country)
    return phone if phone.valid?

    code = Phonelib.phone_data[country][:country_code]
    national = if phone.e164.to_s.start_with?("+#{code}")
                 phone.e164.delete_prefix("+#{code}")
               elsif !number.start_with?('+')
                 number
               end
    return phone unless national

    siblings = calling_code_countries[code].filter_map do |id, leading_digits|
      id if id != country && (!leading_digits || leading_digits.match?(national))
    end
    siblings.any? ? Phonelib.parse(number, siblings) : phone
  end
  private_class_method :parse_phone

  # Each country's patterns for the TYPES, without the short-code patterns
  # phonelib adds when Phonelib.parse_special is on.
  def self.type_patterns
    @type_patterns ||= Phonelib.phone_data.transform_values do |data|
      TYPES.filter_map do |type|
        pattern = data.dig(:types, type, :national_number_pattern)
        pattern && /\A(?:#{pattern})\z/
      end
    end.freeze
  end
  private_class_method :type_patterns

  def self.calling_code_countries
    @calling_code_countries ||= Phonelib.phone_data.values.group_by { |data| data[:country_code] }.transform_values do |countries|
      countries.map { |data| [data[:id], data[:leading_digits] && /\A(?:#{data[:leading_digits]})/] }
    end.freeze
  end
  private_class_method :calling_code_countries

  def initialize(options)
    @countries = Array(options[:countries]).map { |country| country.to_s.upcase } if options.key?(:countries)
    @types = Array(options[:types]).map { |type| type.to_s.to_sym } if options.key?(:types)
    @types = (@types || []) | [:mobile] if options[:mobile]
    super
  end

  def check_validity!
    unknown = options.keys - OPTIONS - ACTIVE_MODEL_OPTIONS
    raise ArgumentError, "Unknown options: #{unknown.map(&:inspect).join(', ')}" if unknown.any?
    raise ArgumentError, 'countries must not be empty' if @countries&.empty?
    raise ArgumentError, 'types must not be empty' if @types&.empty?

    unknown = Array(@types) - TYPES
    raise ArgumentError, "Unknown phone types: #{unknown.map(&:inspect).join(', ')}" if unknown.any?

    [options.fetch(:default_country, DEFAULT_COUNTRY), *@countries].each { |country| self.class.send(:country_code, country) }
  end

  def validate_each(record, attribute, value)
    phone, extension = self.class.send(:analyze, value, options.fetch(:default_country, DEFAULT_COUNTRY))

    if !phone ||
       (extension && !options[:extension]) ||
       (@countries && @countries.none? { |country| phone.valid_for_country?(country) }) ||
       (@types && !acceptable_type?(phone.type))
      record.errors.add(attribute, :invalid, **options.except(*OPTIONS).merge!(value: value))
    end
  end

  private

  def acceptable_type?(type)
    @types.include?(type) ||
      (type == :fixed_or_mobile && @types.intersect?(FIXED_LINE_AND_MOBILE)) ||
      (FIXED_LINE_AND_MOBILE.include?(type) && @types.include?(:fixed_or_mobile))
  end

end
