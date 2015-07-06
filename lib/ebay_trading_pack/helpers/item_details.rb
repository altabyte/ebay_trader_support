require 'ebay_trading/deep_find'

module EbayTradingPack
  module ItemDetails
    include EbayTrading::DeepFind

    # Get the eBay item ID, or nil if not found.
    # @return [Fixnum] eBay item ID.
    #
    def ebay_item_id
      deep_find(details_hash, :item_id)
    end

    # Get the item SKU, which is custom label in the UK.
    # @return [String] the item's SKU.
    #
    def sku
      deep_find(details_hash, :sku)
    end
    alias custom_label sku

    def title
      deep_find(details_hash, :title)
    end

    def url
      deep_find(details_hash, [:listing_detail, :view_item_url])
    end

    def auction?
      deep_find(details_hash, :listing_type) == 'Chinese'
    end

    def fixed_price?
      !auction?
    end

    def bid_count
      deep_find(details_hash, [:selling_status, :bid_count], 0)
    end

    def current_price
      deep_find(details_hash, [:selling_status, :current_price])
    end

    def start_time
      deep_find(details_hash, [:listing_details, :start_time])
    end

    def end_time
      deep_find(details_hash, [:listing_details, :end_time])
    end

    def ended?
      end_time < Time.now
    end

    def active?
      return false if status != :active
      !ended?
    end


    # Get the item selling status.
    # @return [Symbol] :active, :completed or :ended
    #
    def status
      case deep_find details_hash, [:selling_status, :listing_status]
        when 'Active'    then :active
        when 'Completed' then :completed
        when 'Ended'     then :ended
        else
          raise RequestError.new('Invalid item status')
      end
    end

    #
    # Get the duration of this listing, which will be one of 1, 3, 5, 7, 10, 30 or :GTC
    # 0 will be returned if a duration cannot be determined.
    # @return [Fixnum, :GTC] the duration of the listing in days.
    #
    def duration
      duration = deep_find(details_hash, :listing_duration)
      return nil if duration.nil?
      return :GTC if duration == 'GTC'
      match = duration.match(/[0-9]+/)
      return match.nil? ? 0 : match[0].to_i
    end

    # Determine if this is a GTC listing.
    #
    def gtc?
      duration == :GTC
    end

    # Get an array of eBay hosted photo URLs
    # @return [Array] of all photo URLs
    #
    def photo_urls
      photos = deep_find(details_hash, [:picture_details, :picture_url])
      return [] if photos.nil?
      (photos.is_a?(Array)) ? photos : [photos]
    end

    # Get the number of page views for this listing.
    # @return [Fixnum] number of page hits, 0 if none or undetermined.
    def hit_count
      deep_find(details_hash, :hit_count, 0)
    end

    # Count the number of people watching this listing.
    # @return [Fixnum] the number of watchers, or 0 if data not available.
    def watch_count
      deep_find(details_hash, :watch_count, 0)
    end

    # Get the number of items sold from this listing.
    def quantity_sold
      deep_find(details_hash, [:selling_status, :quantity_sold], 0)
    end

    def quantity_listed
      deep_find(details_hash, :quantity, 0)
    end

    #
    # Get the number of available items.
    # This field is included in GetMyeBaySelling, but not GetItem or GetSellerList.
    # @return [Fixnum] number available to sell.
    #
    def quantity_available
      available = deep_find(details_hash, :quantity_available)
      if available.nil?
        return quantity_listed - quantity_sold
      else
        return available.to_i
      end
    end

    #-- Categories -------------------------------------------------------

    def category_1
      cat = deep_find(details_hash, [:primary_category, :category_id])
      cat.nil? ? nil : cat.to_i
    end

    def category_1_path
      path = deep_find(details_hash, [:primary_category, :category_name])
      path.nil? ? [] : path.split(':')
    end

    def store_category_1
      cat = deep_find(details_hash, [:store_front, :store_category_id])
      cat.nil? ? nil : cat.to_i
    end

    def store_category_2
      cat = deep_find(details_hash, [:store_front, :store_category2_id])
      cat.nil? ? nil : cat.to_i
    end


    #-- Best Offer -------------------------------------------------------
    #
    # Determine if best offer is enabled on this listing
    #
    def best_offer?
      deep_find(details_hash, [:best_offer_details, :best_offer_enabled], false)
    end

    #
    # Get the number of best offers placed on this item.
    #
    def best_offer_count
      return 0 unless best_offer?
      deep_find(details_hash, [:best_offer_details, :best_offer_count], 0)
    end

    #
    # Get the best offer automatic accept price.
    # Note: when using GetSellerList ensure :granularity is set to fine.
    # @return [Money, nil]
    #
    def best_offer_auto_accept_price
      return nil unless best_offer?
      deep_find(details_hash, [:listing_details, :best_offer_auto_accept_price])
    end

    #
    # Get the minimum best offer price, below which offers will be automatically rejected.
    # Note: when using GetSellerList ensure :granularity is set to fine.
    # @return [Money, nil]
    #
    def best_offer_minimum_accept_price
      return nil unless best_offer?
      deep_find(details_hash, [:listing_details, :minimum_best_offer_price])
    end

    #
    # Determine if this listing has a promotional sale.
    # @return [boolean] true if this item is in a promotion.
    #
    def promotional_sale?
      !promotional_sale.nil?
    end

    #
    # Get details of the promotional sale, if any, setup my the mark-down manager.
    # @return [Hash, nil]
    #
    def promotional_sale
      sale = deep_find(details_hash, [:selling_status, :promotional_sale_details])
      return nil if sale.nil?
      details = {}
      details[:original_price] = sale[:original_price]
      details[:start_time]     = sale[:start_time]
      details[:end_time]       = sale[:end_time]
      details
    end

    #
    # Determine if this item is on sale now, ie, the current time is between the promotion
    # start and end times.
    #
    def on_sale_now?
      details = promotional_sale
      return false if details.nil?
      return Time.now >= details[:start_time] && Time.now <= details[:end_time]
    end


    #Get a Hash describing the amount of time remaining for this listing.
    # The duration is represented in the ISO 8601 duration format (PnYnMnDTnHnMnS).
    def time_left
      time_left = {
          days:    0,
          hours:   0,
          minutes: 0,
          seconds: 0
      }
      time = deep_find(details_hash, :time_left)
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

    def time_left_in_seconds
      seconds =  time_left[:seconds]
      seconds += time_left[:minutes] * 60
      seconds += time_left[:hours] * 60 * 60
      seconds += time_left[:days] * 60 * 60 * 24
      seconds
    end

    # Get a string representation of the amount of time remaining in days,
    # minutes and seconds.
    def time_left_to_s
      string = ''
      string << "#{time_left[:days].to_s.rjust 2}d " if time_left[:days] > 0
      string << "#{time_left[:hours].to_s.rjust 2}h " if time_left[:hours] > 0
      string << "#{time_left[:minutes].to_s.rjust 2}m" if time_left[:minutes] > 0
      string.strip
    end


    #-- Re-listing -------------------------------------------------------
    #
    # Get the eBay ID of the parent item from which this has been re-listed, if any.
    # @return [Fixnum, nil] the parent ID or nil if this item is not a re-list.
    #
    def relist_parent_id
      deep_find(details_hash, :relist_parent_id)
    end

    def relisted?
      deep_find(details_hash, :relisted, false)
    end

    #
    # If this item has since been re-listed, return the eBay ID of the new listing derived from this one.
    # @return [Fixnum, nil] the eBay ID of the child re-list
    #
    def relist_child_id
      deep_find(details_hash, [:listing_details, :relisted_item_id])
    end

    # Get a Hash of items specifics, where all keys and values Strings.
    # But if there are multiple item specifics with the same key an Array of String values will be returned
    # eg.  { 'Main Colour' => 'Sky blue' } or { 'Purpose' => ["Any Purpose", "Jewellery Making"] }
    # @return [Hash] of item specifics
    #
    def item_specifics
      hash = {}
      specifics = deep_find(details_hash, [:item_specifics, :name_value_list], [])
      specifics = [specifics] unless specifics.is_a?(Array)
      specifics.each { |details| hash[details[:name]] = details[:value] }
      hash
    end

    #-- Variations -------------------------------------------------------
    #
    # The key of this field has been renamed from 'Variations'
    # to 'VariationsSet' in helpers/doctor_item_hash.rb
    #
    # Determine if this listing has any variations.
    #
    def has_variations?
      details_hash.key?(:variety)
    end

    #
    # Get an array of variation details using SKUs as keys.
    # If there are no variations an empty array will be returned.
    # @return [Array] of variation details
    #
    def variations
      raw_variations = deep_find(details_hash, [:variety, :variations])
      list = []
      return list if raw_variations.nil?
      raw_variations = [raw_variations] unless raw_variations.is_a?(Array)
      raw_variations.each do |variation|
        sku = variation[:sku]
        next if sku.nil? || sku.strip.length == 0
        price = variation[:start_price]
        quantity_listed = variation[:quantity].to_i
        selling_status_sold = deep_find(variation, [:selling_status, :quantity_sold])
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
        string << 'was on sale'    if DateTime.now > ends
        string << 'sale scheduled' if DateTime.now < starts
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
        date_time = (Time.now < end_time) ? Time.now : end_time
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