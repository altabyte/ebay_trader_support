require 'active_support/time'

require 'ebay_trader'
require 'ebay_trader/request'

require_relative 'helpers/item_details'
require_relative 'helpers/pagination'

include EbayTrader

module EbayTraderSupport
  class GetSellerEvents < Request
    include Pagination, Enumerable

    CALL_NAME = 'GetSellerEvents'

    # @return [Symbol]
    # Get the events type, which will be one of +:modified+, +:started+ or +:ended+
    attr_reader :event_type

    # @return [Time]
    # The *earliest* time of interest.
    attr_reader :time_from

    # @return [Time]
    # The *latest* time of interest.
    attr_reader :time_to

    # @return [Array<EventItem>]
    # An array of {EventItem}s
    attr_reader :items


    # Get the seller events for listings that were either *started*, *ended* or *modified*
    # within the specified time range.
    # @param [Symbol] event_type +:modified+, +:started+ or +:ended+
    # @param [Time] time_from the earliest Time of interest.
    # @param [Time] time_to the latest Time of interest.
    #
    def initialize(event_type, time_from, time_to, args = {})
      @event_type = event_type
      raise RequestError.new("Event type '#{event_type}' is not valid") unless [:modified, :started, :ended].include?(event_type)
      @time_from = time_from.utc
      raise RequestError('Time from is not valid') unless @time_from.is_a?(Time)
      @time_to = time_to.utc
      raise RequestError('Time to is not valid') unless @time_to.is_a?(Time)

      skip_type_casting = (args[:skip_type_casting] || []).concat(ItemDetails::SKIP_TYPE_CASTING)
      args[:skip_type_casting] = skip_type_casting.uniq

      known_arrays = (args[:known_arrays] || []).concat(ItemDetails::KNOWN_ARRAYS)
      known_arrays.concat [:item] # as Containers always return 1 or more items
      args[:known_arrays] = known_arrays.uniq

      super(CALL_NAME, args) do
        case event_type
          when :modified
            ModTimeFrom   time_from.iso8601(3)
            ModTimeTo     time_to.iso8601(3)
          when :started
            StartTimeFrom time_from.iso8601(3)
            StartTimeTo   time_to.iso8601(3)
          when :ended
            EndTimeFrom   time_from.iso8601(3)
            EndTimeTo     time_to.iso8601(3)
        end
        IncludeWatchCount 'true'
        DetailLevel 'ReturnAll'
      end

      @items = []
      items = response_hash.deep_find([:item_array, :item])
      items = [items] unless items.is_a?(Array)
      items.each do |item_hash|
        @items << EventItem.new(item_hash)
      end
    end

    # Method required to be Enumerable
    def each(&block)
      items.each(&block)
    end

    #=======================================================================
    class EventItem
      include ItemDetails

      attr_reader :item_hash

      def initialize(item_hash)
        @item_hash = item_hash
      end

      # Get a hash of the item details.
      # This method is required for the Item mixin module.
      def to_hash
        @item_hash
      end
    end
  end
end
