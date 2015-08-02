require 'ebay_trading'
require 'ebay_trading/request'

require_relative 'helpers/item_details'

include EbayTrading

module EbayTradingPack

  class GetItem < Request
    include ItemDetails

    CALL_NAME = 'GetItem'

    attr_reader :item_id

    def initialize(auth_token, item_id, args = {})
      item_id = item_id.to_i.freeze
      @item_id = item_id
      @include_description = ((args[:include_description] && args[:include_description] != false) || false).freeze

      skip_type_casting = (args[:skip_type_casting] || []).concat(ItemDetails::SKIP_TYPE_CASTING)
      args[:skip_type_casting] = skip_type_casting.uniq

      known_arrays = (args[:known_arrays] || []).concat(ItemDetails::KNOWN_ARRAYS)
      args[:known_arrays] = known_arrays.uniq

      super(CALL_NAME, auth_token, args) do
        ItemID item_id
        IncludeWatchCount 'true'
        IncludeItemSpecifics 'true'
        DetailLevel 'ItemReturnDescription' if include_description?
      end
    end

    def include_description?
      @include_description
    end

    def item_hash
      response_hash[:item] || {}
    end

  end
end