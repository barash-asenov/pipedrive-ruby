module Pipedrive
  class Person < Base

    class << self

      def find_or_create(params)
        find_by_name(params[:email], :org_id => params[:org_id]).first || create(params)
      end

    end

    def deals
      Deal.all(get "#{resource_path}/#{id}/deals", :everyone => 1)
    end
  end
end
