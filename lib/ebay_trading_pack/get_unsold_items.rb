require 'ebay_trading'
require 'ebay_trading/request'

require_relative 'helpers/item_details'
require_relative 'helpers/pagination'

include EbayTrading

module EbayTradingPack

  class GetUnsoldItems < Request
    include Pagination #, Enumerable

    CALL_NAME = 'GetMyeBaySelling'
    CONTAINER = 'UnsoldList'

    PER_PAGE_DEFAULT = 100

    attr_reader :per_page
    attr_reader :duration_in_days
    attr_reader :page_number  # GetMyeBaySelling responses do NOT include page number!
    attr_reader :items

    def initialize(auth_token, page_number, args = {})
      @page_number = page_number.to_i
      @page_number = 1 if page_number < 1
      @per_page = PER_PAGE_DEFAULT
      if args.key? :per_page
        @per_page = case args[:per_page].to_i
                      when   1..25  then args[:per_page].to_i
                      when  26..50  then 50
                      when  51..100 then 100
                      when 101..200 then 200
                      else
                        PER_PAGE_DEFAULT
                    end
      end
      @duration_in_days = 60    # Min: 0. Max: 60
      if args.key? :duration_in_days
        @duration_in_days = args[:duration_in_days].to_i
        @duration_in_days =  1 if @duration_in_days <  1
        @duration_in_days = 60 if @duration_in_days > 60
      end

      known_arrays = []

      super(CALL_NAME, auth_token, known_arrays: known_arrays, xml_tab_width: 2) do
        ErrorLanguage 'en_GB'
        WarningLevel 'High'
        DetailLevel 'ReturnAll'

        UnsoldList {
          Include 'true'
          DurationInDays duration_in_days  # 0..60
          Pagination {
            EntriesPerPage "#{per_page}"
            PageNumber "#{self.page_number}"
          }
        }

        ActiveList            { Include 'false' }
        BidList               { Include 'false' }
        DeletedFromSoldList   { Include 'false' }
        DeletedFromUnsoldList { Include 'false' }
        ScheduledList         { Include 'false' }
        SoldList              { Include 'false' }
      end

      @items = []
      item_array = find([:unsold_list, :item_array, :item], [])
      item_array = [item_array] unless item_array.is_a? Array
      item_array.each { |item_hash| @items << UnsoldItem.new(item_hash) }
    end

    def each(&block)
      @items.each(&block)
    end

    def has_more_items?
      page_number < total_number_of_pages
    end
  end

  #=======================================================================
  class UnsoldItem
    include ItemDetails

    def initialize(item_hash)
      @item_hash = item_hash
    end

    def status
      :unsold
    end

    #
    # Get a hash of the item details.
    # This method is required by the Item mixin.
    #
    def to_hash
      @item_hash
    end
  end
end