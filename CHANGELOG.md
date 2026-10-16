# Changelog

## 1.0.0

Breaking changes:

- Validation now uses [phonelib](https://github.com/daddyz/phonelib)
  (Google's libphonenumber data) instead of Phony. Numbers must match a
  country's lengths *and* its assigned number ranges, so some numbers Phony
  found plausible are now invalid.
- NANP fictional numbers (555-0100 through 555-0199) are invalid.
- National numbers are read in the `default_country` (US unless set). An
  international number needs a leading `+` or an international dialing
  prefix (`00`, or e.g. `011` from the US).
- Input containing letters (`1-800-FLOWERS`, `555-1234 call me`), a `+`
  anywhere but the start, control characters, or more than 250 characters is
  invalid. Short codes and emergency numbers are invalid.
  `Phonelib.parse_special` and `ignore_plus` are not supported.
- `nil` and blank values are invalid. Set `allow_nil: true` to accept `nil`,
  or `allow_blank: true` to accept `nil` and blank strings.
- Unknown options, unknown or empty `types` and `countries`, and an unknown
  `default_country` raise `ArgumentError`.
- `PhoneValidator.normalize` returns plain E.164 without the extension. Use
  `PhoneValidator.parse` for the extension and display formats. Its
  `extension:` option is replaced by `default_country:`.
- An invalid record gets one `:invalid` error instead of up to two.
- Requires Ruby 3.3+ and ActiveModel 7.1+.
- phonelib ships its own `PhoneValidator`; this gem replaces it in any load
  order. phonelib's validator options (`possible:`, `country_specifier:`,
  ...) raise `ArgumentError`.

Added:

- `default_country:`, `countries:`, `types:` and `mobile:` validator options.
- `PhoneValidator.parse`, returning the E.164 number, extension, country,
  type, and national and international formats.
- Extensions written with `#` or `;`.
- Numbers from any country sharing the default country's calling code, e.g.
  Canadian numbers with the default US.
- `countries:` accepts a number valid in any listed country, e.g. a 1-800
  number with `countries: %w[CA]`.
- `(+44) ...`, full-width digits, Unicode spaces and dashes, and invisible
  marks copied along with a number.

Fixed:

- Input strings are never mutated, so frozen and chilled strings are safe.
- Invalid or non-ASCII-compatible encodings make the number invalid instead
  of raising.

## 0.0.1

Initial release.
