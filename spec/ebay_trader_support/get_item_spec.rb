require 'spec_helper'

require 'json'

require 'ebay_trader'
require 'ebay_trader_support/get_item'

include EbayTrader
include EbayTraderSupport

describe GetItem do

  # Actually, configuration should not be necessary for local XML processing?
  before :all do
    configure_api_production
  end


  context 'when invalid item ID'  do
    let(:item_id) { 123 }
    subject(:item) { GetItem.new(item_id) }

    it 'should return an empty hash' do
      is_expected.not_to be_nil
      is_expected.not_to be_success
      is_expected.to have_errors
      expect(item.item_hash).not_to be_nil
      expect(item.item_hash).to be_a_kind_of(Hash)
      expect(item.item_hash).to be_empty

      puts "Request took #{item.response_time} seconds"
    end
  end

  #
  # Get the details of a currently active item on Tantric Tokyo
  #
  context 'when getting a sellers live item from Production site' do

    before :all do
      @ebay_item_id = 371162058886
      @item = GetItem.new(@ebay_item_id)
    end

    subject(:item) { @item }

    let(:ebay_item_id)  { @ebay_item_id }
    let(:current_price) { 11.89 }


    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
    it { is_expected.not_to have_errors }
    it { is_expected.not_to have_warnings }

    it { expect(item.item_hash).not_to be_nil }
    it { expect(item.item_hash).to be_a Hash }

    it {
      # puts item.to_s(2)  # Print response XML indented with 2 spaces
      puts JSON.pretty_generate item.item_hash
      puts "Request took #{item.response_time} seconds"
    }

    context 'Methods in ItemDetails module' do

      it 'Has an eBay item ID' do
        is_expected.to respond_to :ebay_item_id
        expect(item.ebay_item_id).to eq(ebay_item_id)
        puts "eBay item ID: #{item.ebay_item_id}"
      end

      it 'Has an SKU value' do
        is_expected.to respond_to :sku
        is_expected.to respond_to :custom_label
        expect(item.sku).to eq(item.custom_label)
        puts "SKU: #{item.sku}"
      end

      it { is_expected.to be_fixed_price }
      it { is_expected.not_to be_auction }
      it { expect(item.bid_count).to eq(0) }

      it 'Has a current price' do
        is_expected.to respond_to :current_price
        expect(item.current_price).to be_a Money
        puts "Current price: #{item.current_price.symbol}#{item.current_price}"
      end

      it 'Has a start time' do
        is_expected.to respond_to :start_time
        expect(item.start_time).to be_a Time
        puts "Start time: #{item.start_time}"
      end

      it 'Has an end time' do
        is_expected.to respond_to :end_time
        expect(item.end_time).to be_a Time
        puts "End time:   #{item.end_time}"
      end

      it 'Has a selling status' do
        is_expected.to respond_to :status
        status = item.status
        expect(status).not_to be_nil
        expect([:active, :completed, :ended]).to include(status)
        puts "Listing status: #{status}"
        if status == :active
          expect(item).to be_active
          expect(item).not_to be_ended
        else
          expect(item).not_to be_active
          expect(item).to be_ended
        end
      end

      it 'Has a listing duration' do
        is_expected.to respond_to :duration
        puts "Item duration: #{item.duration}"
        expect([1, 3, 5, 7, 10, 30, :GTC]).to include(item.duration)
        expect(item).to be_gtc if item.duration == :GTC
      end

      it 'should have a hash of item specifics' do
        expect(item.item_specifics).not_to be nil
        expect(item.item_specifics).to be_a(Hash)
      end

      it 'Has photos' do
        is_expected.to respond_to :photo_urls
        photos = item.photo_urls
        expect(photos).to be_a(Array)
        photos.each { |photo| puts photo }
      end

      it 'should have a positive integer hit count' do
        expect(item.hit_count).to be >= 0
        puts "  Hit count: #{item.hit_count}"
      end

      it 'should have a positive integer watch count' do
        expect(item.watch_count).to be >= 0
        puts "  Watch count: #{item.watch_count}"
      end

      it 'should have a primary category' do
        category_1 = item.category_1
        expect(category_1).not_to be nil
        expect(category_1).to be_a(Fixnum)
        expect(category_1).to be > 1

        category_1_path = item.category_1_path
        expect(category_1_path).not_to be nil
        expect(category_1_path).to be_a(Array)
        expect(category_1_path.size).to be > 1

        puts "#{category_1}: #{category_1_path.join(' - ')}"
      end

      it 'Produces a summary' do
        is_expected.to respond_to :summary
        puts "\n\n#{item.summary(true)}\n\n"
      end
    end
  end
end
