# PhoneValidator

PhoneValidator validates phone numbers in ActiveModel objects using
[phonelib](https://github.com/daddyz/phonelib), which is built on Google's
[libphonenumber](https://github.com/google/libphonenumber) data. A number is
valid when it has the right length for its country *and* falls within an
assigned number range. International numbers are supported.

**A valid number is not necessarily in service, and it may not belong to the
person who entered it.** To know either, verify the number by SMS or with a
carrier lookup.

Requires Ruby 3.3+ and ActiveModel 7.1+.

## Installation

Add this line to your application's Gemfile:

    gem 'phone_validator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install phone_validator

phonelib ships a validator named `PhoneValidator` too. This gem replaces it,
so `validates :phone, phone: ...` always uses the options described below.

## Usage

Add the following validation to your model:

    validates :phone, phone: true

National numbers are read as US numbers unless `default_country` says
otherwise. Numbers from other countries that share the default country's
calling code are accepted too, so Canadian numbers are valid with the US
default. Any other country's numbers need a leading `+` or an international
dialing prefix (`00`, or the default country's own, such as `011` from the
US):

    validates :phone, phone: { default_country: 'GB' }

Valid input contains digits, spaces and `- . ( ) /`, an optional leading `+`,
and an optional extension. Input with letters (such as `1-800-FLOWERS`), line
breaks or other control characters, or more than 250 characters is invalid.
`(+44) ...` is accepted, as are full-width digits, Unicode spaces and dashes,
and the invisible marks some phones add when a number is copied. Short codes and emergency numbers
(such as `911`) and the fictional NANP numbers 555-0100 through 555-0199 are
invalid.

### Options

| Option            | Default | Description |
| ----------------- | ------- | ----------- |
| `default_country` | `'US'`  | ISO 3166 country code used to read national numbers. |
| `countries`       | any     | Only accept numbers from these countries, e.g. `%w[US CA]`. |
| `types`           | any     | Only accept these number types, e.g. `[:mobile]` or `[:toll_free]`. See `PhoneValidator::TYPES` for the full list. |
| `mobile`          | `false` | Shorthand for adding `:mobile` to `types`. |
| `extension`       | `false` | Accept numbers with an extension (`x123`, `ext. 123`, `extension 123`, `#123`, `;123`). Extensions are rejected unless this is `true`. |
| `allow_blank`     | `false` | Accept `nil` and blank strings. `allow_nil` accepts only `nil`. |
| `message`         |         | Custom error message. The error type is always `:invalid`. |

Unknown options, types and countries, and empty `countries` or `types`
lists, raise `ArgumentError` when the validation is declared. This includes
the options of phonelib's own validator (`possible`, `extensions`,
`country_specifier`, ...), so a model written for it fails loudly instead of
being validated differently.

#### Mobile numbers

    validates :phone, phone: { mobile: true }

`mobile: true` rejects fixed lines, toll-free, premium-rate, and other
non-mobile numbers. Some countries, including the US and Canada, don't
distinguish mobile numbers from fixed lines. Their numbers have the type
`:fixed_or_mobile`, which `mobile: true` accepts. Likewise, `types:
[:fixed_line]` accepts `:fixed_or_mobile` numbers, and `types:
[:fixed_or_mobile]` accepts fixed lines and mobiles.

### Normalizing and parsing

`PhoneValidator.normalize` returns a number in E.164 format, without any
extension, or `nil` if the number is invalid:

    PhoneValidator.normalize('(234) 235-5678 x 12')                # => "+12342355678"
    PhoneValidator.normalize('020 7123 4567', default_country: 'GB') # => "+442071234567"
    PhoneValidator.normalize('invalid')                            # => nil

`PhoneValidator.parse` returns a `PhoneValidator::Result`, or `nil` if the
number is invalid:

    result = PhoneValidator.parse('(234) 235-5678 x 12')
    result.e164          # => "+12342355678"
    result.extension     # => "12"
    result.country       # => "US"
    result.type          # => :fixed_or_mobile
    result.national      # => "(234) 235-5678"
    result.international # => "+1 234-235-5678"

Neither method applies the validator's `countries`, `types`, or `extension`
options. Both raise `ArgumentError` for an unknown `default_country`.

To store numbers in E.164 with Active Record, normalize with the same
`default_country` the validator uses. `normalizes` runs before validation and
drops any extension, so don't combine it with `extension: true`:

    normalizes :phone, with: ->(phone) { PhoneValidator.normalize(phone, default_country: 'GB') || phone }
    validates :phone, phone: { default_country: 'GB' }

### phonelib settings

PhoneValidator hands phonelib only digits, so `Phonelib.strict_check`,
`sanitize_regex` and `extension_separate_symbols` don't change its results.
`Phonelib.default_country` is not used; pass `default_country:` instead.

`Phonelib.parse_special` and `Phonelib.ignore_plus` are not supported. With
`parse_special` on, phonelib can read a short input as a longer number the
user never typed (PhoneValidator still rejects the short codes themselves).
With `ignore_plus` on, international numbers become invalid.

## Development

    $ bundle install
    $ bundle exec rake test

Set `ACTIVEMODEL_VERSION` (e.g. `7.1`) to test against another ActiveModel
version.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
