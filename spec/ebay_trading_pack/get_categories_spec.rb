require 'spec_helper'

require 'ebay_trading'
require 'ebay_trading_pack/get_categories'

include EbayTrading
include EbayTradingPack

describe GetCategories do

  # Actually, configuration should not be necessary for local XML processing?
  before :all do
    configure_api_sandbox
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']
  end
  let(:auth_token) { @auth_token }


  context 'when no base category is blank or invalid' do

    it 'should output eBay root categories if category_number.to is zero' do
      root_categories = ''
      [nil, 'INVALID', 0].each do |category_number|
        categories = GetCategories.new(auth_token, category_number)
        expect(categories).not_to be nil
        expect(categories).to be_success
        expect(categories).not_to have_warnings
        expect(categories).not_to have_errors

        root_categories = categories.to_s
        expect(root_categories.length).to be > 0
      end
      puts "\n\nRoot Categories\n\n#{root_categories}\n\n"
    end


    it 'should raise an error for to_s if category is an unrecognized positive integer' do
      begin
        invalid_category = 5_000_000_000
        categories = GetCategories.new(auth_token, invalid_category)
        expect(categories).not_to be nil
        expect(categories).not_to be_success
        expect(categories).not_to have_warnings
        expect(categories).to be_failure
        expect(categories).to have_errors
        expect(categories.errors).to be_a(Array)
        expect(categories.errors.count).to be 1
        expect(categories.errors.first[:long_message]).to eq('Input data for tag <CategoryParent> is invalid or missing. Please check API documentation.')
        puts categories.to_json_s
      rescue Exception => e
        puts e
        expect(true).to be false  # Should never get to this point!
      end
    end
  end


  context 'valid base category is provided' do

    it 'should output a tree of sub-categories for UK Jewellery' do
      jewellery_category_uk = 281
      categories = GetCategories.new(auth_token, jewellery_category_uk)
      expect(categories).not_to be nil

      expect(categories).to be_success
      expect(categories).not_to be_failure

      expect(categories).not_to have_errors
      expect(categories.errors).to be_a(Array)
      expect(categories.errors.count).to be 0

      expect(categories).not_to have_warnings
      expect(categories.warnings).to be_a(Array)
      expect(categories.warnings.count).to be 0

      expect(categories.response_hash).to be_a Hash
      expect(categories.response_hash).to be_a HashWithIndifferentAccess
      expect(categories.response_hash).to respond_to :deep_find

      string =  categories.to_s
      expect(string).not_to be nil
      expect(string.length).to be > 0
    end


    # http://jewelry.listings.ebay.com/_W0QQloctZShowCatIdsQQsacatZ281QQsalocationZatsQQsocmdZListingCategoryOverview
    it 'should produce different sub-categories for UK and USA sites' do
      puts 'Getting jewellery sub-category for UK site...'
      jewellery_category_uk = 281
      uk = GetCategories.new(auth_token, jewellery_category_uk, ebay_site_id: 3)
      expect(uk).not_to be nil
      expect(uk).to be_success
      expect(uk).not_to have_warnings
      expect(uk).not_to have_errors
      uk_data = uk.to_s
      expect(uk_data.length).to be > 0

      puts 'Getting jewellery sub-categories for USA site...'
      jewellery_category_usa = jewellery_category_uk   # UK and USA have same jewellery/jewelry category IDs
      usa = GetCategories.new(auth_token, jewellery_category_usa, ebay_site_id: 0)
      expect(usa).not_to be nil
      expect(usa).to be_success
      expect(usa).not_to have_warnings
      expect(usa).not_to have_errors
      usa_data = usa.to_s
      expect(usa_data.length).to be > 0

      expect(usa_data).not_to eq(uk_data)
      puts 'Confirmed that UK and USA jewellery categories are different'
    end


    # http://crafts.listings.ebay.co.uk/_W0QQloctZShowCatIdsQQsacatZ14339QQsalocationZlicQQsocmdZListingCategoryOverview
    # Crafts -> Beads -> Gemstone -> Amethyst
    it 'should display only information about the current category if it is a leaf' do
      crafts_beads = 34091
      categories = GetCategories.new auth_token, crafts_beads
      expect(categories).to be_success
      expect(categories).not_to have_errors
      expect(categories).not_to have_warnings
      string =  categories.to_s.strip.gsub(/\s+/, ': ')
      expect(string.length).to be > 0
      expect(string).to match /^Amethyst/
      expect(string).to match /#{crafts_beads}$/
      puts "\nCategories for UK Crafts -> Beads -> Gemstone -> Amethyst:\n\n#{string}\n\n"
    end
  end

end