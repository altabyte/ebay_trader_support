require 'ebay_trader'
require 'ebay_trader/request'

include EbayTrader

module EbayTraderSupport

  class GetCategorySpecifics < Request

    CALL_NAME = 'GetCategorySpecifics'

    attr_reader :category_number

    def initialize(category_number, args = {})
      category_number = category_number.to_i
      raise EbayTraderError, 'Please provide a valid root category number' unless category_number > 0

      super(CALL_NAME, args) do
        CategorySpecific do
          CategoryID category_number
        end
      end

      @category_number = category_number
    end

    def to_s
      string = ''
      recommendations = deep_find([:recommendations, :name_recommendation])
      unless recommendations.nil?
        recommendations = [recommendations] unless recommendations.is_a? Array
        recommendations.each do |recommend|
          next unless recommend.key?(:name)
          string << " * #{recommend[:name]}\n"
          if recommend.key?(:value_recommendation)
            values = recommend[:value_recommendation]
            values = [values] unless values.is_a?(Array)
            values.each do |value|
              string << "     #{value[:value]}\n" if value.is_a? Hash
            end
          end
        end
      end
      string
    end
  end
end
