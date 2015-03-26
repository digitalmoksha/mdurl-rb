require File.expand_path('../lib/mdurl-rb/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'mdurl-rb'
  gem.version       = MDUrl::VERSION
  gem.authors       = ["Brett Walker", "Vitaly Puzrin", "Alex Kocharin"]
  gem.email         = 'github@digitalmoksha.com'
  gem.summary       = "MDUrl for motion-markdown-it in Ruby"
  gem.description   = "Ruby version of MDUrl for motion-markdown-it for use with Ruby and RubyMotion"
  gem.homepage      = 'https://github.com/digitalmoksha/mdurl-rb'
  gem.licenses      = ['MIT']

  gem.files         = Dir.glob('lib/**/*.rb')
  gem.files        << 'README.md'
  gem.test_files    = Dir.glob('spec/**/*.rb')

  gem.require_paths = ["lib"]

  gem.add_dependency 'motion-support', '~> 0.2.6'  # only used in RubyMotion version
end