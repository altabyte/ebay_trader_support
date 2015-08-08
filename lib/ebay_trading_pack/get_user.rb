require 'ebay_trading'
require 'ebay_trading/request'

include EbayTrading

module EbayTradingPack

  # Get the details for an eBay user.
  #
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/GetUser.html
  #
  class GetUser < Request
    CALL_NAME = 'GetUser'

    # @return [String] the username of the eBay user whose details are being requested.
    attr_reader :user_id

    # @return [Fixnum] the listing item ID, or +nil+ if not provided in the constructor.
    attr_reader :item_id

    # Make a call to the eBay API requesting details for a particular user.
    # If a +user_id+ is not specified in the arguments, details of the calling user
    # shall be returned.
    #
    # @param auth_token [String] the eBay Auth Token for the user submitting this request.
    #
    # @param args [Hash] a hash of optional settings.
    #
    # @option args [String] :user_id the eBay username of the user.
    #
    # @option args [String] :item_id the item ID for a successfully concluded listing in which the requestor and target user were participants (one as seller and the other as buyer).
    #
    def initialize(auth_token, args = {})
      @user_id = args[:user_id] || nil
      @item_id = args[:item_id] || nil
      @item_id = @item_id.to_i unless @item_id.nil?

      super(CALL_NAME, auth_token, args) do
        UserID user_id unless user_id.nil?
        ItemID item_id.to_s unless item_id.nil?
      end

      @user_id = deep_find([:user, :user_id])
    end

    # Get the hash of information containing user details.
    #
    # @return [Hash] a Hash of eBay user details.
    #
    def user_hash
      response_hash.key?(:user) ? response_hash[:user] : {}
    end
  end
end