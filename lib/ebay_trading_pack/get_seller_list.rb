require 'active_support/time'

require 'ebay_trading'
require 'ebay_trading/request'

require_relative 'helpers/item_details'
require_relative 'helpers/pagination'

include EbayTrading

module EbayTradingPack

  #
  # Get a list of the seller's items.
  # By default the list is based upon item :end_time as this will ensure that
  # all items are accessible. GTC items have a virtual end time.
  # If using :start_time only items which were listed within the time frame
  # will be accessible, as GTC automatic re-listing does not seem to count!
  # If the list is :based_on :end_time the list will be sorted by time descending.
  # If the list is :based_on :start_time the list will be sorted by time ascending.
  #
  class GetSellerList < Request
    include Pagination, Enumerable

    CALL_NAME = 'GetSellerList'

    PER_PAGE_DEFAULT = 100
    DAYS_DEFAULT     = 30

    # Note: Best offer prices are only available when granularity is 'Fine'
    GRANULARITY_DEFAULT = 'Coarse'

    #attr_reader :page_number, :total_number_of_pages, :total_number_of_listings
    attr_reader :days, :per_page, :granularity

    # The eBay username of the seller whose list of items is requested
    # @return [String] the seller's eBay user ID.
    attr_reader :seller_id


    # Get a list of items for sale from a seller.
    #
    # @param auth_token [String] the eBay Auth Token for the user submitting this request.
    #
    # @param page_number [Fixnum] the page number requested.
    #
    # @param args [Hash] a hash of optional configuration values.
    #
    # @option args [String] :auth_token override the auth_token value in {Configuration#auth_token}.
    #
    # @option args [String] :seller_id the eBay user ID of the seller. If omitted the seller ID will be the owner of the +auth_token+.
    #
    # @option args [Fixnum] :per_page number of items per page. Can be 25, 50, 100 or 200.
    #
    # @option args [DateTime, String] :time the start or end time of the item listings.
    #
    # @option args [Symbol] :based_on can be +:end_time+ (default) or +:start_time+.
    #
    # @option args [Fixnum] :days the number of days from +:time+ [1..120]
    #
    # @option args [Symbol] :sort can be :descending (default for +:end_time+) or :ascending (default for +:start_time+).
    #
    def initialize(page_number, args = {})

      page_number = page_number.to_i
      page_number = 1 if page_number < 1
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

      @seller_id = args[:seller_id]

      # Use :end_time as the default range type
      @based_on = (args.key?(:based_on) && args[:based_on] == :start_time) ? :start_time : :end_time

      @sort = based_on_start_time? ? :ascending : :descending
      @sort = (args[:sort] == :ascending) ? :ascending : :descending  if args.key?(:sort)

      # The maximum number of days is 120.
      @days = (args[:days] || DAYS_DEFAULT).to_i
      @days =   1 if @days < 1
      @days = 120 if @days > 120

      time = Time.now
      if args.key?(:time)
        if args[:time].is_a? Time
          time = args[:time]
        elsif args[:time].is_a? String
          time = Time.parse args[:time]
        end
      else
        if based_on_end_time?
          time = Time.now + 30.days # The next 30 days from now
        else
          time = Time.now - @days.days
        end
      end

      if based_on_end_time?
        @time_range = [time - @days.days, time]
      else
        @time_range = [time, time + @days.days]
      end

      # http://developer.ebay.com/Devzone/XML/docs/Reference/ebay/types/GranularityLevelCodeType.html
      @granularity = GRANULARITY_DEFAULT
      if args[:granularity]
        @granularity = case args[:granularity].to_s.downcase
                         when 'course'  then 'Course'
                         when 'medium'  then 'Medium'
                         when 'fine'    then 'Fine'
                         else
                           GRANULARITY_DEFAULT
                       end
      end

      skip_type_casting = (args[:skip_type_casting] || []).concat(ItemDetails::SKIP_TYPE_CASTING)
      args[:skip_type_casting] = skip_type_casting.uniq

      known_arrays = (args[:known_arrays] || []).concat(ItemDetails::KNOWN_ARRAYS)
      known_arrays.concat [:item] # as Containers always return 1 or more items
      args[:known_arrays] = known_arrays.uniq

      super(CALL_NAME, args) do
        ErrorLanguage 'en_GB'
        WarningLevel 'High'

        UserID seller_id unless seller_id.blank?

        #DetailLevel 'ReturnAll'
        GranularityLevel granularity
        IncludeWatchCount 'true'
        IncludeVariations 'true'

        if based_on_end_time?
          EndTimeFrom time_from.to_s
          EndTimeTo time_to.to_s
        else
          StartTimeFrom time_from.to_s
          StartTimeTo time_to.to_s
        end


        # Specifies the order in which returned items are sorted (based on the end dates of the item listings).
        # 0 = No sorting
        # 1 = Sort in descending order
        # 2 = Sort in ascending order
        Sort descending? ? '1' : '2'

        Pagination {
          EntriesPerPage per_page
          PageNumber page_number
        }
      end


      # Build the list of item details.
      @items = []
      item_array = response_hash.deep_find([:item_array, :item], [])
      item_array = [item_array] unless item_array.is_a? Array
      item_array.each { |item_hash| @items << SellerItem.new(item_hash) }
    end

    def has_more_items?
      more = response_hash.deep_find(:has_more_items, false)
      ['true', true].include?(more)
    end

    #
    # Is this list based upon item start time.
    #
    def based_on_start_time?
      @based_on == :start_time
    end

    #
    # Is this list based upon item end time.
    #
    def based_on_end_time?
      !based_on_start_time?
    end

    #
    # The earliest (oldest) date in the time range of seller items.
    #
    def time_from
      @time_range[0]
    end

    #
    # The most recent date in the time range of seller items.
    #
    def time_to
      @time_range[1]
    end

    def ascending?
      @sort == :ascending
    end

    def descending?
      !ascending?
    end

    #
    # Get an array of the seller's list of items.
    #
    def items
      @items || []
    end

    #
    # Method required by Enumerable
    #
    def each(&block)
      items.each(&block)
    end

  end


  #=======================================================================
  class SellerItem
    include ItemDetails

    attr_reader :item_hash

    def initialize(item_hash)
      @item_hash = item_hash.freeze
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