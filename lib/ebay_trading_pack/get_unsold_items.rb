require 'ebay_trading'
require 'ebay_trading/request'

require_relative 'helpers/item_details'
require_relative 'helpers/pagination'

include EbayTrading

module EbayTradingPack

  # Helper class to get an eBay user's list of unsold items.
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetMyeBaySelling.html
  class GetUnsoldItems < Request
    include Pagination, Enumerable

    CALL_NAME = 'GetMyeBaySelling'
    CONTAINER = 'UnsoldList'

    PER_PAGE_DEFAULT = 100

    DURATION_IN_DAYS_DEFAULT = 60

    # The page number requested.
    #
    # @note +GetMyeBaySelling+ calls do NOT include page numbers in their responses. So the page number returned will always be that given in the constructor.
    # @return [Fixnum] the page number.
    attr_reader :page_number

    # The maximum number of items to be returned in each page,
    # with a default of {PER_PAGE_DEFAULT}.
    # @return [Fixnum] the number of items per page.
    attr_reader :per_page

    # Specifies the time period during which an item was won or lost.
    # Similar to the period drop-down menu in the My eBay user interface.
    # For example, to return the items won or lost in the last week,
    # specify a duration_in_days of 7.
    # @return [Fixnum] the number of days since the items ended.
    attr_reader :duration_in_days

    # @return [Array[UnsoldItem]] Get a list of unsold items on this page.
    attr_reader :items

    # Get a count of the total number of item unsold.
    # @return [Fixnum] the number of unsold items.
    alias_method :total_number_unsold, :total_number_of_entries

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
      @duration_in_days = DURATION_IN_DAYS_DEFAULT # Min: 0. Max: 60
      if args.key? :duration_in_days
        @duration_in_days = args[:duration_in_days].to_i
        @duration_in_days =  1 if @duration_in_days <  1
        @duration_in_days = 60 if @duration_in_days > 60
      end

      known_arrays = args[:known_arrays] || []
      known_arrays.concat [:item, :shipping_service_options, :variation]
      args[:known_arrays] = known_arrays

      super(CALL_NAME, auth_token, args) do
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
      item_array = deep_find([:unsold_list, :item_array, :item], [])
      item_array = [item_array] unless item_array.is_a? Array
      item_array.each { |item_hash| @items << UnsoldItem.new(item_hash) }
    end

    def each(&block)
      @items.each(&block)
    end

    def has_more_items?
      page_number < total_number_of_pages
    end

    #-------------------------------------------------------------------------
    protected

    # Override the method definition in the included {Pagination} module
    # as +GetMyeBaySelling+ calls require pagination per container.
    # @return [Array[String|Symbol]] a list of element names pointing to the pagination information.
    # @see EbayTradingPack::Pagination#pagination_path
    def pagination_path
      [:unsold_list, :pagination_result]
    end
  end

  #=======================================================================
  class UnsoldItem
    include ItemDetails

    attr_reader :item_hash

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