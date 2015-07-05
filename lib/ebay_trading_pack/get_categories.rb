require 'ebay_trading'
require 'ebay_trading/request'

include EbayTrading

module EbayTradingPack

  class GetCategories < Request

    CALL_NAME = 'GetCategories'

    attr_reader :root_category_number
    attr_reader :level_limit

    def initialize(auth_token, root_category_number, args = {})
      unless root_category_number.nil?
        root_category_number = root_category_number.to_i
        root_category_number = nil unless root_category_number > 0
      end
      @root_category_number = root_category_number

      @level_limit = (args[:level_limit] || 5).to_i
      @level_limit = 1 if @root_category_number.nil?

      ebay_site_id = (args[:ebay_site_id] || EbayTrading.configuration.ebay_site_id).to_i

      super(CALL_NAME, auth_token, ebay_site_id: ebay_site_id, xml_tab_width: 2) do
        CategorySiteID ebay_site_id
        CategoryParent root_category_number unless root_category_number.nil?
        DetailLevel 'ReturnAll'
        LevelLimit level_limit
        ViewAllNodes 'true'
      end
    end

    # Return a string representation of the eBay categories.
    # If full is true it will render the entire response hash in YAML format.
    #
    def to_s(full = false)
      raise RequestError, 'Unable to obtain category information!' unless success?
      if full
        puts response_hash.to_yaml
      else
        @categories = {}
        category_array = find(%w'category_array category')
        unless category_array.nil?
          category_array = [category_array] unless category_array.is_a? Array
          category_array.each do |category|
            @categories[category[:category_id].to_i] = {
                :id => category[:category_id].to_i,
                :name => category[:category_name],
                :level => category[:category_level].to_i,
                :parent_id => (category[:category_parent_id].to_i != category[:category_id].to_i ? category[:category_parent_id].to_i : nil),
                :children => []
            }
          end
        end

        # Build the children arrays
        unless root_category_number.nil?
          @categories.each_value do |category|
            unless category[:parent_id].nil? || @categories[category[:parent_id]].nil?
              @categories[category[:parent_id]][:children] << category[:id]
            end
          end
          category_to_s(root_category_number)
        else
          string = ''
          @categories.each_pair do |id, data|
            string << "#{id.to_s.rjust(8)}   #{data[:name]}\n"
          end
          string
        end
      end
    end

    #---------------------------------------------------------------------------
    private

    def category_to_s(category_number)
      category = @categories[category_number]
      return '' unless category
      indent = 3 * (category[:level] - 1)
      string = ''.ljust(indent)
      string << category[:name].ljust(45 - indent)
      string << "#{category[:id]}".rjust(8)
      string << "\n"
      category[:children].each { |child_id| string << category_to_s(child_id) }
      string
    end
  end
end
