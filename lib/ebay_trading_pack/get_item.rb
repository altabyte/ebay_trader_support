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

      known_arrays = ['picture_url']

      super(CALL_NAME, auth_token, known_arrays: known_arrays) do
        ItemID item_id
        IncludeWatchCount 'true'
        IncludeItemSpecifics 'true'
        DetailLevel 'ItemReturnDescription' if include_description?
      end
    end

    def include_description?
      @include_description
    end

    def details_hash
      response_hash[:item] || {}
    end

  end
end