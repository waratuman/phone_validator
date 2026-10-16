Gem::Specification.new do |spec|
  spec.name          = 'phone_validator'
  spec.version       = '1.0.0'
  spec.authors       = ['James R. Bracy']
  spec.email         = ['waratuman@gmail.com']
  spec.description   = %q{ActiveModel validator for phone numbers, backed by libphonenumber data via phonelib}
  spec.summary       = %q{Phone number validation for Rails}
  spec.homepage      = 'https://github.com/waratuman/phone_validator'
  spec.license       = 'MIT'

  spec.metadata      = {
    'changelog_uri' => 'https://github.com/waratuman/phone_validator/blob/master/CHANGELOG.md',
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 3.3'

  spec.files         = Dir['lib/**/*.rb', 'CHANGELOG.md', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel', '>= 7.1'
  spec.add_dependency 'phonelib', '~> 0.10.6'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest', '>= 5.20'
  spec.add_development_dependency 'minitest-reporters'
end
