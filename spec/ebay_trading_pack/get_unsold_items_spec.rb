require 'spec_helper'

require 'ebay_trader'
require 'ebay_trading_pack/get_unsold_items'

include EbayTrader
include EbayTradingPack

describe GetUnsoldItems do

  before :all do
    configure_api_production
  end

  describe 'requesting 1st page of unsold items' do
    before :all do
      @page_number      = 1
      @per_page         = 5
      @duration_in_days = 60
      @unsold = GetUnsoldItems.new(@page_number,
                                   per_page: @per_page,
                                   duration_in_days: @duration_in_days)
    end

    let(:page_number)      { @page_number }
    let(:per_page)         { @per_page }
    let(:duration_in_days) { @duration_in_days }

    subject(:unsold) { @unsold }

    it {
      unless unsold.count == 0
        #puts "#{unsold.xml_request}\n\n"
        #puts "#{unsold.to_s(2)}\n\n"
        puts "#{JSON.pretty_generate unsold.response_hash[:unsold_list]}\n\n"
      end
    }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
    it {
      expect(unsold.count).to be_between(0, per_page)
      puts "Number of unsold items on this page is: #{unsold.count}"
    }


    describe 'pagination' do

      it 'should be on page number 1' do
        expect(unsold.page_number).not_to be_nil
        expect(unsold.page_number).to be_a(Fixnum)
        expect(unsold.page_number).to eq(1)
        puts "Page number:             #{unsold.page_number}"

        expect(unsold.per_page).not_to be_nil
        expect(unsold.per_page).to be_a(Fixnum)
        expect(unsold.per_page).to eq(per_page)
        puts "Per page:                #{unsold.per_page}"
      end

      it 'should get the total number of pages' do
        expect(unsold.total_number_of_pages).not_to be_nil
        expect(unsold.total_number_of_pages).to be_a(Fixnum)
        expect(unsold.total_number_of_pages).to be >= 0
        puts "Total number of pages:   #{unsold.total_number_of_pages}"
      end

      it 'should get the total number of listings' do
        expect(unsold.total_number_unsold).to eq(unsold.total_number_of_entries)
        expect(unsold.total_number_unsold).not_to be_nil
        expect(unsold.total_number_unsold).to be_a(Fixnum)
        expect(unsold.total_number_unsold).to be >= 0
        expect(unsold.total_number_unsold).to be >= unsold.count
        puts "Total number of entries: #{unsold.total_number_unsold}"
      end

      it 'should have the correct number of pages for the number of listings' do
        pages = unsold.total_number_of_entries.to_f / per_page
        expect(pages.ceil).to eq(unsold.total_number_of_pages)
      end
    end


    describe 'Items' do
      it 'should have 0..per_page items' do
        count = unsold.count
        expect(count).to be_between(0, per_page).inclusive
        puts "Number of unsold items on this page: #{count}"
      end

      it 'should provide a list of unsold item IDs' do
        unsold.each do |item|
          puts "#{item.summary}\n\n"
        end
      end
    end
  end
end
