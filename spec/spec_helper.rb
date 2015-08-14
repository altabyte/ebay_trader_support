$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ebay_trading_pack'

require 'redis'


def configure_api_production
  configure_api_environment :production
end

def configure_api_sandbox
  configure_api_environment :sandbox
end


private

def configure_api_environment(env)
  raise 'Environment must be either :production or :sandbox' unless [:production, :sandbox].include?(env)

  EbayTrading.configure do |config|

    config.ebay_api_version = 933

    config.environment      = env

    config.ebay_site_id     = 3 # ebay.co.uk

    config.price_type       = :money

    config.dev_id  = ENV['EBAY_API_DEV_ID']
    config.app_id  = ENV['EBAY_API_APP_ID']
    config.cert_id = ENV['EBAY_API_CERT_ID']

    config.counter = lambda {
      begin
        redis = Redis.new(host: 'localhost')
        key = "ebay_trading:#{env.to_s}:call_count:#{Time.now.utc.strftime('%Y-%m-%d')}"
        redis.incr(key)
      rescue SocketError
        raise 'Failed to increment Redis call counter!'
      end
    }
  end
end
