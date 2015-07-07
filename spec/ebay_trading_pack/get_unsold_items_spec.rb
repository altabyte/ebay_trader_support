require 'ebay_trading_pack/get_unsold_items'

require 'ebay_trading'
require 'ebay_trading_pack/get_item'

include EbayTrading
include EbayTradingPack

describe GetUnsoldItems do

  # Actually, configuration should not be necessary for local XML processing?
  before :all do
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TT']
  end
  let(:auth_token) { @auth_token }

  before :all do
    EbayTrading.configure do |config|
      config.environment  = :production
      config.price_type   = :money
      config.ebay_site_id = 3 # ebay.co.uk
      config.dev_id  = ENV['EBAY_API_DEV_ID']
      config.app_id  = ENV['EBAY_API_APP_ID']
      config.cert_id = ENV['EBAY_API_CERT_ID']
    end
  end

  describe 'requesting 1st page of unsold items' do
    before :all do
      @page_number      = 1
      @per_page         = 5
      @duration_in_days = 30
      @unsold_items = GetUnsoldItems.new(@auth_token,
                                         @page_number,
                                         per_page: @per_page,
                                         duration_in_days: @duration_in_days)
    end

    let(:page_number)      { @page_number }
    let(:per_page)         { @per_page }
    let(:duration_in_days) { @duration_in_days }

    subject(:unsold_items) { @unsold_items }

    it {
      #puts "#{unsold_items.xml_request}\n\n"
      #puts "#{unsold_items.to_s(2)}\n\n"
      puts "#{JSON.pretty_generate unsold_items.response_hash[:unsold_list]}\n\n"
    }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
  end

end