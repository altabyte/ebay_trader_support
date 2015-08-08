require 'ebay_trading'
require 'ebay_trading_pack/get_seller_list'

include EbayTrading
include EbayTradingPack

describe GetSellerList do

  before :all do
    EbayTrading.configure do |config|
      config.environment  = :production
      config.price_type   = :money
      config.ebay_site_id = 3 # ebay.co.uk
      config.dev_id  = ENV['EBAY_API_DEV_ID']
      config.app_id  = ENV['EBAY_API_APP_ID']
      config.cert_id = ENV['EBAY_API_CERT_ID']
    end
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TT']
  end
  let(:auth_token) { @auth_token }

  context 'When auth_token belongs to the seller' do

    context 'When getting a single item' do
      before :all do
        @page_number = 1
        @per_page    = 1
        @seller_list = GetSellerList.new(@auth_token, @page_number, per_page: @per_page)
      end

      let(:page_number) { @page_number }
      let(:per_page)    { @per_page }

      subject(:seller_list) { @seller_list }

      it { is_expected.not_to be_nil }
      it { is_expected.to be_success }

      it {
        #puts "#{seller_list.xml_request}\n\n"
        #puts "#{seller_list.to_s(2)}\n\n"
        puts "#{JSON.pretty_generate seller_list.response_hash[:item_array]}\n\n"
      }

      describe 'Pagination' do
        it 'should return the page number' do
          expect(seller_list.page_number).to eq(page_number)
          puts "Page number:             #{seller_list.page_number}"
          puts "Total number of pages:   #{seller_list.total_number_of_pages}"
          puts "Total number of entries: #{seller_list.total_number_of_entries}"
        end
      end

      it 'should return an array with a single item' do
        expect(seller_list.items).not_to be nil
        expect(seller_list.items).to be_a(Array)
        expect(seller_list.items).not_to be_empty
        expect(seller_list.items.size).to eq(per_page)
      end

      it 'should have a single valid item' do
        item = seller_list.items.first
        expect(item).not_to be_nil
        validate_item(item)
        puts "#{item.ebay_item_id} - '#{item.title}'"
      end
    end


    context 'When requesting 2 items' do

      before :all do
        @page_number = 1
        @per_page = 2
        @seller_list = GetSellerList.new(@auth_token, @page_number, per_page: @per_page)
      end

      let(:page_number) { @page_number }
      let(:per_page)    { @per_page }

      subject(:seller_list) { @seller_list }

      it { is_expected.not_to be_nil }
      it { is_expected.to be_success }

      it 'should be one page of many' do
        expect(seller_list.total_number_of_pages).to be >= 1
        expect(seller_list.per_page).to eq(per_page)

        puts "Page #{page_number} of #{seller_list.total_number_of_pages} with #{per_page} items per page."
        puts "Total number of listings is: #{seller_list.total_number_of_entries} based on #{seller_list.based_on_end_time? ? 'end time' : 'start time'}"

      end

      it 'should return 2 hashes' do
        expect(seller_list.items).not_to be nil
        expect(seller_list.items).to be_a(Array)
        expect(seller_list.items).not_to be_empty
        expect(seller_list.items.size).to eq(per_page)
      end

      it 'should return valid items' do
        seller_list.each { |item| validate_item(item) }
      end
    end


    context 'When iterating pages of results to get all seller items' do

      let(:per_page)     { 200 }
      let(:perform_test) { false }

      it 'should get a list of items for each page of available data' do

        # This is a very slow test, ~90 seconds for 1,000 items
        # so maybe don't always want to run this test?
        if perform_test
          count       = 0
          page_number = 0
          match_items = []
          time = Time.now
          begin
            seller_list = GetSellerList.new(auth_token, page_number += 1, per_page: per_page)
            expect(seller_list).not_to be_nil
            expect(seller_list).to be_success
            expect(page_number).to eq(seller_list.page_number)
            count += seller_list.count
            puts "Page #{page_number} of #{seller_list.total_number_of_pages}"

            seller_list.each do |item|
              match_items << item if item.title =~ /[ ]set/i && item.title !~ /CCB/i
            end
          end while seller_list.has_more_items?
          puts "\nElapsed time: #{(Time.now - time).to_i} seconds\n"

          match_items.each { |item| puts "#{item.ebay_item_id} - #{item.sku.ljust(6)} : '#{item.title}'" }

          expect(page_number).to eq(seller_list.total_number_of_pages)
          expect(count).to eq(seller_list.total_number_of_entries)
        end
      end
    end
  end


  context 'When getting items listed on a different selling account' do
    before :all do
      @seller_id = 'currys_pcworld'
      @page_number = 1
      @per_page    = 10
      @seller_list = GetSellerList.new(@auth_token, @page_number, seller_id: @seller_id, per_page: @per_page)
    end

    let(:seller_id)   { @seller_id }
    let(:page_number) { @page_number }
    let(:per_page)    { @per_page }

    subject(:seller_list) { @seller_list }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }

    it 'should return valid items' do
      puts "#{JSON.pretty_generate seller_list.response_hash[:item_array]}\n\n"
      seller_list.each { |item| validate_item(item) }
    end
  end


  #---------------------------------------------------------------------------
  private

  def validate_item(item)

    puts "\n-----------------------------------------------------------------------"
    puts "  Validating eBay item: #{item.ebay_item_id}"

    puts "  eBay ID: #{item.ebay_item_id}"

    expect(item.ebay_item_id).not_to be nil
    expect(item.ebay_item_id).to be_a(Fixnum)
    expect(item.ebay_item_id).to be > 0

    expect(item.sku).not_to be_nil
    expect(item.sku).not_to be_blank
    puts "  SKU: #{item.sku}"

    expect(item.title).not_to be_nil
    expect(item.title.length).to be_between(10, 80)
    puts "  Title: '#{item.title}'"
    :item_id
    expect(item.current_price).not_to be_nil
    expect(item.current_price).to be_a(Money)
    puts "  Price: #{item.current_price.symbol}#{item.current_price.to_s}"

    expect(item.url).not_to be_nil
    expect(item.url).to match(/^http:\/\/www.ebay.co.uk\/itm/i)
    expect(item.url).to match(/#{item.ebay_item_id}$/)
    puts "  URL: #{item.url}"

    expect(item.photo_urls).not_to be nil
    expect(item.photo_urls).to be_a(Array)
    expect(item.photo_urls.count).to be >= 1
    puts "  Listing has #{item.photo_urls.count} photos"
    item.photo_urls.each { |url| puts "    #{url}" }

    expect(item.status).to be :active
    expect(item.start_time).not_to be_nil
    expect(item.end_time).not_to be_nil
    puts "  Start Time: #{item.start_time.strftime('%-d %b %y - %H:%M').rjust(18)}"
    puts "  End Time:   #{item.end_time.strftime('%-d %b %y - %H:%M').rjust(18)}"
    expect(item).to be_active
    expect(item.end_time).to be > Time.now.utc

    # Do not check start time as this call will also return scheduled items!
    # expect(item.start_time).to be < Time.now.utc

    expect(item.quantity_listed).to be >= 1
    expect(item.quantity_sold).to be >= 0
    expect(item.quantity_available).to be item.quantity_listed - item.quantity_sold
    puts "  Quantity: #{item.quantity_available}  ->  #{item.quantity_listed} listed, #{item.quantity_sold} sold"

    expect(item.hit_count).to be >= 0
    puts "  Hit count: #{item.hit_count}"

    expect(item.watch_count).to be >= 0
    puts "  Watch count: #{item.watch_count}"

    category_1 = item.category_1
    expect(category_1).not_to be nil
    expect(category_1).to be_a(Fixnum)
    expect(category_1).to be > 1

    category_1_path = item.category_1_path
    expect(category_1_path).not_to be nil
    expect(category_1_path).to be_a(Array)
    expect(category_1_path.size).to be > 1

    puts "  Category: #{category_1} => #{category_1_path.join(' - ')}"

    expect(item.item_specifics).not_to be nil
    expect(item.item_specifics).to be_a(Hash)

    expect(item.summary).not_to be nil
    #puts
    #puts item.summary

    puts ''
  end

end
