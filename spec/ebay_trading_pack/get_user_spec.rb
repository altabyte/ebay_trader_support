require 'spec_helper'

require 'securerandom'

require 'ebay_trading'
require 'ebay_trading_pack/get_user'

include EbayTrading
include EbayTradingPack

describe GetUser do

  before :all do
    configure_api_production
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TT']
  end
  let(:auth_token) { @auth_token }


  context 'Without specifying user_id in the args' do
    before :all do
      @get_user = GetUser.new(@auth_token)
    end

    subject(:user) { @get_user }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }

    it { puts "#{JSON.pretty_generate user.response_hash}\n\n" }

    it { expect(user.user_id).to eq(ENV['EBAY_API_USERNAME_TT']) }
  end


  context 'When a valid eBay user ID is provided' do
    before :all do
      @get_user = GetUser.new(@auth_token, user_id: ENV['EBAY_API_USERNAME_AR'])
    end

    subject(:user) { @get_user }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }

    it { puts "#{JSON.pretty_generate user.response_hash}\n\n" }

    it { expect(user.user_id).to eq(ENV['EBAY_API_USERNAME_AR']) }
  end


  context 'When the given eBay user ID does not exist' do
    before :all do
      @random_user_id = "#{SecureRandom.uuid.to_s}-#{SecureRandom.uuid.to_s}"
      @get_user = GetUser.new(@auth_token, user_id: @random_user_id)
    end

    subject(:user) { @get_user }

    it { is_expected.not_to be_nil }
    it { is_expected.not_to be_success }
    it { is_expected.to be_failure }
    it { is_expected.to have_errors }
    it { expect(user.errors.first[:short_message]).to eq('Invalid User ID.') }
  end
end