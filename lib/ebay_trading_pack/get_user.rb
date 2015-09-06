require 'ebay_trader'
require 'ebay_trader/request'

include EbayTrader

module EbayTradingPack

  # Get the details for an eBay user.
  #
  # @see http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/GetUser.html
  #
  class GetUser < Request
    CALL_NAME = 'GetUser'

    KNOWN_ARRAYS = [
        :charity_affiliation_detail,
        :site,
        :skype_id,
        :supported_site,
        :top_rated_program,
        :user_subscription
    ]

    SKIP_TYPE_CASTING = [
        :charity_id,
        :city_name,
        :international_street,
        :phone,
        :postal_code,
        :name,
        :skype_id,
        :street,
        :street1,
        :street2,
        :user_id,
        :vat_id
    ]

    # @return [String] the username of the eBay user whose details are being requested.
    attr_reader :user_id

    # @return [Fixnum] the listing item ID, or +nil+ if not provided in the constructor.
    attr_reader :item_id

    # Make a call to the eBay API requesting details for a particular user.
    # If a +user_id+ is not specified in the arguments, details of the calling user
    # shall be returned.
    #
    # @param args [Hash] a hash of optional settings.
    #
    # @param args [String] :auth_token override the auth_token value in {Configuration#auth_token}.
    #
    # @option args [String] :user_id the eBay username of the user.
    #
    # @option args [String] :item_id the item ID for a successfully concluded listing in which the requestor and target user were participants (one as seller and the other as buyer).
    #
    def initialize(args = {})
      @user_id = args[:user_id] || nil
      @item_id = args[:item_id] || nil
      @item_id = @item_id.to_i unless @item_id.nil?

      skip_type_casting = (args[:skip_type_casting] || []).concat(SKIP_TYPE_CASTING)
      args[:skip_type_casting] = skip_type_casting.uniq

      known_arrays = (args[:known_arrays] || []).concat(KNOWN_ARRAYS)
      args[:known_arrays] = known_arrays.uniq

      super(CALL_NAME, args) do
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
