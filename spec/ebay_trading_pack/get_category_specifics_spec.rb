require 'ebay_trading'
require 'ebay_trading_pack/get_category_specifics'

include EbayTrading
include EbayTradingPack

describe GetCategorySpecifics do

  # Actually, configuration should not be necessary for local XML processing?
  before :all do
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']
  end
  let(:auth_token) { @auth_token }

  before do
    EbayTrading.configure do |config|
      config.environment = :sandbox
      config.ebay_site_id = 3 # ebay.co.uk
      config.dev_id  = ENV['EBAY_API_DEV_ID_SANDBOX']
      config.app_id  = ENV['EBAY_API_APP_ID_SANDBOX']
      config.cert_id = ENV['EBAY_API_CERT_ID_SANDBOX']
    end
  end

  context 'When getting valid category specifics' do

    let(:category_ids) {
      {
          10185  => 'Jewellery & Watches => Loose Diamonds & Gemstones => Loose Gemstones => Agate',
          34090  => 'UK Crafts => Beads => Gemstone => Agate',
          164332 => 'Jewellery & Watches => Fine Jewellery => Fine Necklaces & Pendants => Gemstone',
          164315 => 'Jewellery & Watches => Fine Jewellery => Fine Bracelets => Gemstone',
          164321 => 'Jewellery & Watches => Fine Jewellery => Fine Earrings => Gemstone'
      }
    }

    it 'retrieves data' do
      category_ids.each_pair do |category_id, path|
        puts "#{category_id}: #{path}"
        category_specifics = GetCategorySpecifics.new(auth_token, category_id)
        expect(category_specifics).to be_success
        expect(category_specifics).not_to have_errors
        expect(category_specifics).not_to have_warnings
        string = category_specifics.to_s
        expect(string).not_to be_blank
        puts "#{string}\n\n"
      end
    end
  end
end
