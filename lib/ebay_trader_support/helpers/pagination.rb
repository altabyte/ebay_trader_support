module EbayTraderSupport
  module Pagination

    def page_number
      response_hash.deep_find(:page_number, 0).to_i
    end

    def total_number_of_entries(&block)
      response_hash.deep_find(pagination_path.concat([:total_number_of_entries]), 0).to_i

    end

    def total_number_of_pages
      response_hash.deep_find(pagination_path.concat([:total_number_of_pages]), 0).to_i
    end

    #-----------------------------------------------------------------------
    protected

    # Get an array of the path keys pointing to the pagination data.
    # Generally this will be under the root of response_hash in a key called
    # :pagination_result, however GetSellerList calls will first require
    # the container path.
    # For example the pagination paths for GetSellerList will include
    # [ActiveList, PaginationResult] and [UnsoldList, PaginationResult] etc.
    #
    # To change the path override this method.
    def pagination_path
      [:pagination_result]
    end
    
  end
end
