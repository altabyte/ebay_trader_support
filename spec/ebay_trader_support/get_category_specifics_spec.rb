require 'spec_helper'

require 'ebay_trader'
require 'ebay_trader_support/get_category_specifics'

include EbayTrader
include EbayTraderSupport

describe GetCategorySpecifics do

  # Actually, configuration should not be necessary for local XML processing?
  before :all do
    configure_api_sandbox
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']
  end
  let(:auth_token) { @auth_token }


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
        category_specifics = GetCategorySpecifics.new(category_id)
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
