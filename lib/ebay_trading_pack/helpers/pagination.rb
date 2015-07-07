module EbayTradingPack
  module Pagination

    def page_number
      deep_find(response_hash, :page_number, 0).to_i
    end

    def total_number_of_entries
      deep_find(response_hash, pagination_path.concat([:total_number_of_entries]), 0).to_i

    end

    def total_number_of_pages
      deep_find(response_hash, pagination_path.concat([:total_number_of_pages]), 0).to_i
    end

    #-----------------------------------------------------------------------
    protected

    # Get an array of the path keys to the pagination data.
    # Generally this will be under the root of response_hash in a key called PaginationResult,
    # however GetSellerList calls will first require the container path.
    # For example the pagination paths for GetSellerList will include
    # [ActiveList, PaginationResult] and [UnsoldList, PaginationResult] etc.
    #
    # To change the path override this method.
    def pagination_path
      [:pagination_result]
    end
    
  end
end
