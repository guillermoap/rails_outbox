# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.authors               = ['Guillermo Aguirre']
  spec.files                 = Dir['LICENSE.txt', 'README.md', 'lib/**/*', 'lib/rails_outbox.rb']
  spec.name                  = 'rails_outbox'
  spec.summary               = 'A Transactional Outbox implementation for ActiveRecord and Rails'
  spec.version               = '0.1.0'

  spec.email                 = 'guillermoaguirre@hey.com'
  spec.executables           = ['outbox']
  spec.homepage              = 'https://github.com/guillermoap/rails_outbox'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'dry-configurable', '~> 1.0'
  spec.add_dependency 'rails', '>= 6.1'
end
