# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ebay_trading_pack/version'

Gem::Specification.new do |spec|
  spec.name          = 'ebay-trading-pack'
  spec.version       = EbayTradingPack::VERSION
  spec.authors       = ['Rob Graham']
  spec.email         = ['altabyte@gmail.com']

  spec.summary       = %q{A suite of tools for accessing eBay's Trading API}
  spec.description   = <<-DESC
    A suite of tools for accessing eBay's Trading API.
  DESC
  spec.homepage      = 'http://www.altabyte.com'
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

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_runtime_dependency 'activesupport',  '~> 4.0'
  spec.add_runtime_dependency 'ebay-trading',   '0.8.1'
end
