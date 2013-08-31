# PhoneValidator

PhoneValidator provides simple validation for phone numbers in ActiveModel
objects. Only phone numbers from the [North American Numbering Plan](http://en.wikipedia.org/wiki/North_American_Numbering_Plan)
are supported.

Pattern:

    ITUCC ::=  ('+' ? '1')                                          (* ITU Country Calling Code *)
    NPA ::= '[2-9]' '[0-8]' '\d'                                    (* Numbering Plan Area Code *)
    CO ::= \d (('0' '\d') | ('1' ('0' | '[2-9]')) | ('[2-9]' '\d')) (* Central Office (Exchange) Code *)
    SN ::= '\d{4}'                                                  (* Subscriber Number *)
    EXT ::= ' ' ? (('x' '.'?) | ('ext' '.' ? ) | 'extension' ) ' ' ? '\d+' (* Extension *)
    SEP ::= '-' | ' ' | '.'                                         (* Seperator *)

    PHONE ::= (ITUCC SEP?)? (('( ?' NPA ' ?)') | NPA)  SEP? CO SEP? SN EXT

    /\A
    ((\+? ?1)([- \.]?))?
    ((\( ?[2-9][0-8]\d ?\))|([2-9][0-8]\d))
    ([- \.]?)?
    ([2-9]((0\d)|(1[02-9])|([2-9]\d)))
    ([- \.]?)?
    (\d{4})
    ( ?((x\.?)| |\.|(ext\.?)|extension|ex\.?) ?(\d+))?
    \z/i

    /\A((\+? ?1)([- \.]?))?((\( ?([2-9][0-8]\d) ?\))|([2-9][0-8]\d))([- \.]?)?([2-9]((0\d)|(1[02-9])|([2-9]\d)))([- \.]?)?(\d{4})( ?(x\.?| |\.|(ext\.?)|extension|ex\.?) ?(\d+))?\z/i

## Installation

Add this line to your application's Gemfile:

    gem 'phone_validator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install phone_validator

## Usage

Add the following validation to your model:

    validates :attribute_name, :phone => true

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
