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

  EbayTrader.configure do |config|

    config.ebay_api_version = 935

    config.environment      = env

    config.ebay_site_id     = 3 # ebay.co.uk

    config.price_type       = :money

    config.ssl_verify       = false

    config.dev_id  = (env == :production) ? ENV['EBAY_API_DEV_ID']  : ENV['EBAY_API_DEV_ID_SANDBOX']
    config.app_id  = (env == :production) ? ENV['EBAY_API_APP_ID']  : ENV['EBAY_API_APP_ID_SANDBOX']
    config.cert_id = (env == :production) ? ENV['EBAY_API_CERT_ID'] : ENV['EBAY_API_CERT_ID_SANDBOX']

    config.auth_token = (env == :production) ? ENV['EBAY_API_AUTH_TOKEN_TT'] : ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']

    config.counter = lambda {
      begin
        redis = Redis.new(host: 'localhost')
        key = "ebay_trader:#{env.to_s}:call_count:#{Time.now.utc.strftime('%Y-%m-%d')}"
        redis.incr(key)
      rescue SocketError
        raise 'Failed to increment Redis call counter!'
      end
    }
  end
end
