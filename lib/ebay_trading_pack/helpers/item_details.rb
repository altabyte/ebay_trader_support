require 'ebay_trading'

module EbayTradingPack

  # A collection of helper methods to extract details from a single item hash.
  # Classes wishing to include this module must expose the original eBay API
  # response item details with a +*item_hash*+ method.
  #
  # Note: Methods in this module make extensive use of the +deep_find+ method.
  # This has been mixed into the +HashWithIndifferentAccess+ class defined
  # in the {https://github.com/altabyte/ebay_trading ebay-trading} gem.
  module ItemDetails

    # @return [Array [Symbol]] an array of the +Symbol+ keys whose values are known to be arrays.
    KNOWN_ARRAYS ||= [
        :compatibility,
        :copyright,
        :cross_border_trade,
        :discount_profile,
        :ebay_picture_url,
        :exclude_ship_to_location,
        :external_picture_url,
        :gift_services,
        :international_shipping_service_option,
        :item_specifics,
        :listing_enhancement,
        :name_value_list,
        :payment_allowed_site,
        :payment_methods,
        :promoted_item,
        :picture_url,
        :shipping_service_options,
        :ship_to_location,
        :ship_to_locations,
        :skype_contact_option,
        :tax_jurisdiction,
        :value,
        :variation,
        :variation_specific_picture_set,
        :variation_specifics,
        :variation_specifics_set
    ]

    # @return [Array [Symbol]] an array of  the +Symbol+ keys whose values are not to be automatically type cast.
    SKIP_TYPE_CASTING ||= [
        :sku,
        :postal_code
    ]

    # Get the eBay item ID of this listing.
    # @return [Fixnum] eBay item ID.
    #
    def item_id
      item_hash.deep_find(:item_id)
    end
    alias ebay_item_id item_id

    # Get the item SKU, which is called custom label in the UK.
    # @return [String] the item's SKU.
    #
    def sku
      item_hash.deep_find(:sku)
    end
    alias custom_label sku

    # Get the title text of this item listing.
    # @return [String] the item's title.
    #
    def title
      item_hash.deep_find(:title)
    end

    # Get the public URL of this item on eBay's web site.
    # @return [String] the item listing URL.
    #
    def url
      item_hash.deep_find([:listing_details, :view_item_url])
    end

    # Determine if this is an auction format listing.
    # @return [Boolean] true if auction.
    #
    def auction?
      item_hash.deep_find(:listing_type) == 'Chinese'
    end

    # Determine if this is a fixed-price buy-it-now format listing.
    # @return [Boolean] true if not auction format.
    #
    def fixed_price?
      !auction?
    end

    # Get the number of bids on this listing. This will always be 0
    # unless it is an {#auction?} listing.
    # @return [Fixnum] the number of bids.
    #
    def bid_count
      item_hash.deep_find([:selling_status, :bid_count], 0)
    end

    # The item's current selling price.
    # If this item is currently on {#promotional_sale?} the current price
    # will be the discounted price.
    # @return [Money] the selling price.
    #
    def current_price
      item_hash.deep_find([:selling_status, :current_price])
    end

    # Get the start time of this listing.
    # @return [Time] the listing start time.
    #
    def start_time
      item_hash.deep_find([:listing_details, :start_time])
    end

    # Get the listing end time.
    # @return [Time] the listing end time.
    #
    def end_time
      item_hash.deep_find([:listing_details, :end_time])
    end

    # Determine if this listing has now ended.
    # @return [Boolean] true if listing has ended.
    #
    def ended?
      end_time < Time.now.utc
    end

    # Determine if this item is currently active.
    # @return [Boolean] true if an active listing.
    #
    def active?
      return false if status != :active
      !ended?
    end

    # Get the item selling status.
    # @return [Symbol] :active, :completed or :ended
    #
    def status
      case item_hash.deep_find [:selling_status, :listing_status]
        when 'Active'    then :active
        when 'Completed' then :completed
        when 'Ended'     then :ended
        else
          raise EbayTradingError.new('Invalid item status')
      end
    end

    # Get the duration of this listing, which will be one of 1, 3, 5, 7, 10, 30 or :GTC
    # 0 will be returned if a duration cannot be determined.
    # @return [Fixnum|:GTC] the duration of the listing in days.
    #
    def duration
      duration = item_hash.deep_find(:listing_duration)
      return nil if duration.nil?
      return :GTC if duration == 'GTC'
      match = duration.match(/[0-9]+/)
      return match.nil? ? 0 : match[0].to_i
    end

    # Determine if this is a Good Time Cancelled [GTC] listing.
    # @return [Boolean] true if GTC.
    #
    def gtc?
      duration == :GTC
    end

    # Get an array of eBay hosted photo URLs
    # @return [Array[String]] of all photo URLs
    #
    def photo_urls
      photos = item_hash.deep_find([:picture_details, :picture_url])
      return [] if photos.nil?
      (photos.is_a?(Array)) ? photos : [photos]
    end

    # Get the number of page views for this listing.
    # @return [Fixnum] number of page hits, 0 if none or undetermined.
    #
    def hit_count
      item_hash.deep_find(:hit_count, 0)
    end

    # Count the number of people watching this listing.
    # @return [Fixnum] the number of watchers, or 0 if data not available.
    #
    def watch_count
      item_hash.deep_find(:watch_count, 0)
    end

    # Get the number of items sold from this item listing.
    # @return [Fixnum] the number sold.
    #
    def quantity_sold
      item_hash.deep_find([:selling_status, :quantity_sold], 0)
    end

    # Get the quantity of items originally listed.
    # @return [Fixnum] the number of item listed.
    #
    def quantity_listed
      item_hash.deep_find(:quantity, 0)
    end

    #
    # Get the number of available items.
    # This field is included in GetMyeBaySelling, but not GetItem or GetSellerList.
    # @return [Fixnum] number available to sell.
    #
    def quantity_available
      available = item_hash.deep_find(:quantity_available)
      if available.nil?
        return quantity_listed - quantity_sold
      else
        return available.to_i
      end
    end

    #-- Categories -------------------------------------------------------

    # Get the name of the primary category.
    # @return [String] the primary category name.
    #
    def category_1
      cat = item_hash.deep_find([:primary_category, :category_id])
      cat.nil? ? nil : cat.to_i
    end

    # Get the primary category path.
    # @return [String] path to category.
    #
    def category_1_path
      path = item_hash.deep_find([:primary_category, :category_name])
      path.nil? ? [] : path.split(':')
    end

    # Get the store primary category ID.
    # @return [Fixnum] the ID number of the primary store category.
    #
    def store_category_1
      cat = item_hash.deep_find([:store_front, :store_category_id])
      cat.nil? ? nil : cat.to_i
    end

    # Get the store secondary category ID.
    # @return [Fixnum] the ID number of the second store category.
    #
    def store_category_2
      cat = item_hash.deep_find([:store_front, :store_category2_id])
      cat.nil? ? nil : cat.to_i
    end


    #-- Best Offer -------------------------------------------------------

    # Determine if this item listing has best offer feature enabled.
    # @return [Boolean] true if has best offer.
    #
    def best_offer?
      item_hash.deep_find([:best_offer_details, :best_offer_enabled], false)
    end

    # Get the number of best offers placed on this item.
    # @return [Fixnum] the number of offers.
    #
    def best_offer_count
      return 0 unless best_offer?
      item_hash.deep_find([:best_offer_details, :best_offer_count], 0)
    end


    # Get the best offer automatic accept price.
    # Note: when using GetSellerList ensure :granularity is set to fine.
    # @return [Money, nil]
    #
    def best_offer_auto_accept_price
      return nil unless best_offer?
      item_hash.deep_find([:listing_details, :best_offer_auto_accept_price])
    end

    # Get the minimum best offer price, below which offers will be automatically rejected.
    # Note: when using GetSellerList ensure :granularity is set to fine.
    # @return [Money, nil]
    #
    def best_offer_minimum_accept_price
      return nil unless best_offer?
      item_hash.deep_find([:listing_details, :minimum_best_offer_price])
    end

    # Determine if this listing has a promotional sale.
    # @return [boolean] true if this item is in a promotion.
    #
    def promotional_sale?
      !promotional_sale.nil?
    end

    # Get details of the promotional sale, if any, setup my the mark-down manager.
    # @return [Hash, nil]
    #
    def promotional_sale
      sale = item_hash.deep_find([:selling_status, :promotional_sale_details])
      return nil if sale.nil?
      details = {}
      details[:original_price] = sale[:original_price]
      details[:start_time]     = sale[:start_time]
      details[:end_time]       = sale[:end_time]
      details
    end

    # Determine if this item is on sale now, ie, the current time is between the promotion
    # start and end times.
    # @return [Boolean] true if on sale.
    def on_sale_now?
      details = promotional_sale
      return false if details.nil?
      return Time.now.utc >= details[:start_time] && Time.now.utc <= details[:end_time]
    end


    # Get a Hash describing the amount of time remaining for this listing.
    # The duration is represented in the ISO 8601 duration format (PnYnMnDTnHnMnS).
    # @return [Hash] with the keys days, hours, minutes and seconds.
    #
    def time_left
      time_left = {
          days:    0,
          hours:   0,
          minutes: 0,
          seconds: 0
      }
      time = item_hash.deep_find(:time_left)
      unless time.nil?
        matcher = time.match(/P([0-9]+D)?T([0-9]+H)?([0-9]+M)?([0-9]+S)?/i)
        if matcher
          time_left[:days]    = matcher[1].to_i
          time_left[:hours]   = matcher[2].to_i
          time_left[:minutes] = matcher[3].to_i
          time_left[:seconds] = matcher[4].to_i
        end
      end
      time_left
    end

    # Get the time remaining in seconds.
    # @note This is based upon the TimeLeft element in the response XML and is NOT real-time accurate.
    # @return [Fixnum] seconds remaining until this listing expires.
    def time_left_in_seconds
      seconds =  time_left[:seconds]
      seconds += time_left[:minutes] * 60
      seconds += time_left[:hours] * 60 * 60
      seconds += time_left[:days] * 60 * 60 * 24
      seconds
    end

    # Get a string representation of the amount of time remaining in days,
    # minutes and seconds. This could be useful for rendering on a web page.
    # @return [String] summary of days, hours and minutes remaining.
    #
    def time_left_to_s
      string = ''
      string << "#{time_left[:days].to_s.rjust 2}d " if time_left[:days] > 0
      string << "#{time_left[:hours].to_s.rjust 2}h " if time_left[:hours] > 0
      string << "#{time_left[:minutes].to_s.rjust 2}m" if time_left[:minutes] > 0
      string.strip
    end


    #-- Re-listing -------------------------------------------------------

    # Get the eBay ID of the parent item from which this has been re-listed, if any.
    # @return [Fixnum, nil] the parent ID or nil if this item is not a re-list.
    #
    def relist_parent_id
      item_hash.deep_find(:relist_parent_id)
    end

    # Determine if this listing has been relisted from a previously expired listing.
    # @return [Boolean] true if relisted.
    def relisted?
      item_hash.deep_find(:relisted, false)
    end

    # If this item has since been re-listed, return the eBay ID of the new listing derived from this one.
    # @return [Fixnum, nil] the eBay ID of the child re-list
    #
    def relist_child_id
      item_hash.deep_find([:listing_details, :relisted_item_id])
    end

    # Get a Hash of items specifics, where all keys and values Strings.
    # But if there are multiple item specifics with the same key an Array of String values will be returned
    # eg.  { 'Main Colour' => 'Sky blue' } or { 'Purpose' => ["Any Purpose", "Jewellery Making"] }
    # @return [Hash] of item specifics
    #
    def item_specifics
      hash = {}
      return hash unless item_hash.key?(:item_specifics) && item_hash[:item_specifics].is_a?(Array)
      name_value_list = item_hash[:item_specifics].first
      return hash unless name_value_list.is_a?(Hash) && name_value_list.key?(:name_value_list)
      specifics = name_value_list[:name_value_list]
      specifics = [specifics] unless specifics.is_a?(Array)
      specifics.each { |details| hash[details[:name]] = !details[:value].empty? ? details[:value].first : '' }
      hash
    end

    #-- Variations -------------------------------------------------------

    # Determine if this listing has any variations.
    # @return [Boolean] true if there are variations in this listing.
    #
    def has_variations?
      item_hash.key?(:variations)
    end

    # Get an array of variation details using SKUs as keys.
    # If there are no variations an empty array will be returned.
    # @return [Array] of variation details
    #
    def variations
      raw_variations = item_hash.deep_find([:variations, :variation])
      list = []
      return list if raw_variations.nil?
      raw_variations = [raw_variations] unless raw_variations.is_a?(Array)
      raw_variations.each do |variation|
        sku = variation[:sku]
        next if sku.nil? || sku.strip.length == 0
        price = variation[:start_price]
        quantity_listed = variation[:quantity].to_i
        selling_status_sold = variation.deep_find([:selling_status, :quantity_sold])
        quantity_sold = selling_status_sold.nil? ? 0 : selling_status_sold.to_i
        quantity_available = quantity_listed - quantity_sold
        list << { sku: sku.strip,
                  current_price: price,
                  quantity_available: quantity_available,
                  quantity_listed: quantity_listed,
                  quantity_sold: quantity_sold }
      end
      list
    end


    # Get a text-based summary
    # @return [String] summary description.
    #
    def summary(include_item_specifics = false)
      string = title.ljust(80)
      string << "[#{status.to_s}]".capitalize.rjust(15)

      if has_variations?
        string << "\n   #{variations.count} Variations:"
        variations.each do |variation|
          string << "\n     #{variation[:sku]}: "
          string << "#{variation[:quantity_available].to_s.rjust(3)} @ #{(variation[:current_price].symbol + variation[:current_price].to_s).rjust(6)}"
          string << "    #{variation[:quantity_listed].to_s.rjust(2)} listed, #{variation[:quantity_sold].to_s.rjust(2)} sold"
        end
      else
        string << "\n   "
        string << "#{quantity_available.to_s} @ "
        string << "#{current_price.symbol}#{current_price.to_s}"
        if best_offer?  # Cannot have best offer on variations
          string << ' with Best Offer'
          string << " #{best_offer_auto_accept_price.symbol}#{best_offer_auto_accept_price}" if best_offer_auto_accept_price
          string << " | #{best_offer_minimum_accept_price.symbol}#{best_offer_minimum_accept_price}" if best_offer_minimum_accept_price
        end
      end

      if promotional_sale?
        details        = promotional_sale
        starts         = details[:start_time]
        ends           = details[:end_time]
        original_price = promotional_sale[:original_price]
        string << "\n      "
        string << 'ON SALE NOW!'   if on_sale_now?
        string << 'was on sale'    if Time.now.utc > ends
        string << 'sale scheduled' if Time.now.utc < starts
        string << " original price #{original_price.symbol}#{original_price.to_s}"
        string << "  #{starts.strftime('%H:%M %A')}"
        string << " until #{ends.strftime('%H:%M %A')}"
      end
      string << "\n"

      string << "#{quantity_sold.to_s.rjust(4)} sold"
      if quantity_sold > 0 && status == :completed
        days = (end_time - start_time).round.to_i
        if days > 1
          string << " in #{days} days"
        else
          hours = ((end_time.to_time - start_time.to_time) / 1.hour).round
          string << " in #{hours} hours"
        end
      end

      string << ", #{watch_count} watchers, #{hit_count} page views."
      string << "\n"

      string << "   SKU: #{sku}      Photos: #{photo_urls.count}      eBay ID: "
      string << "#{relist_parent_id} <= " unless relist_parent_id.nil?
      string << "#{ebay_item_id}"
      string << " => #{relist_child_id}" unless relist_child_id.nil?

      string << "\n   "
      if gtc?
        date_time = (Time.now.utc < end_time) ? Time.now.utc : end_time
        days = (date_time - start_time).round.to_i
        if days > 1
          string << "GTC [#{days} days]"
        else
          hours = ((date_time.to_time - start_time.to_time) / 1.hour).round
          string << "GTC [#{hours} hours]"
        end

      else
        string << "#{duration} Day"
      end
      string << "    #{category_1_path.join(' -> ')}"

      string << "\n   "
      string << "#{start_time.strftime('%l:%H%P %A %-d %b').strip} until #{end_time.strftime('%l:%H%P %A %-d %b').strip}"

      if include_item_specifics
        item_specifics.each_pair do |key, value|
          string << "\n#{key.rjust(30)}  :  #{value}"
        end
      end

      string
    end
  end
end