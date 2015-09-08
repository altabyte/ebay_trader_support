# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ebay_trader_support/version'

Gem::Specification.new do |spec|
  spec.name          = 'ebay-trader-support'
  spec.version       = EbayTraderSupport::VERSION
  spec.authors       = ['Rob Graham']
  spec.email         = ['rob@altabyte.com']

  spec.summary       = %q{eBay Trading API utilities and command line tools build using the ebay-trader gem.}
  spec.description   = <<-DESC
    eBay Trading API utilities and command line tools build using the ebay-trader gem.

    I have made this gem available on GitHub to show examples of how I use the ebay-trader gem.
    Please feel free to copy functionality you require for your own business needs.
  DESC
  spec.homepage      = 'https://github.com/altabyte/ebay_trader_support'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}).keep_if { |f| File.executable?(f) }.map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',    '~> 1.10'
  spec.add_development_dependency 'rake',       '~> 10.0'
  spec.add_development_dependency 'redis',      '~> 3.0'
  spec.add_development_dependency 'rspec'

  spec.add_runtime_dependency 'activesupport',  '~> 4.0'
  spec.add_runtime_dependency 'ebay-trader',    '~> 0.9'
  spec.add_runtime_dependency 'money',          '~> 6.6'
end
