require 'spec_helper'

require 'ebay_trading'
require 'ebay_trading_pack/get_seller_events'

include EbayTrading
include EbayTradingPack

describe GetSellerEvents do

  before :all do
    configure_api_production
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TT']
  end
  let(:auth_token) { @auth_token }

  context 'when listings ended in the last 24 hours' do

    before :all do
      @time_to = Time.now
      @time_from = @time_to - 24.hours
      @event_type = :ended

      puts "\nGetting seller events for listings '#{@event_type.to_s}' between #{@time_from} and #{@time_to}\n\n"
      @events = GetSellerEvents.new(@auth_token, @event_type, @time_from, @time_to, xml_tab_width: 2)
    end

    subject(:events) { @events }

    it { is_expected.not_to be nil }
    it { is_expected.to be_success }
    it { expect(events.event_type).to be @event_type }
    it { expect(events.items).to be_a(Array) }

    it 'should provide an array of items' do
      expect(events.items.size).to be >= 0
      puts "Found #{events.items.size} #{@event_type.to_s} items:"
      events.items.each { |item|
        puts "\n#{item.summary}\n"
      }
    end

    it 'should return something' do
      puts JSON.pretty_generate events.response_hash
    end

  end
end
