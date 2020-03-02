# frozen_string_literal: true

module Pipedrive
  ##
  # Stage API endpoint methods
  class Stage < Base
    class << self
      def deals(id)
        Deal.all(get("#{resource_path}/#{id}/deals", query: { everyone: 1 }))
      end
    end
  end
end
