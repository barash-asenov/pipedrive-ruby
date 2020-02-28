module Pipedrive
  class Organization < Base

    def persons
      Person.all(get "#{resource_path}/#{id}/persons")
    end

    def deals
      Deal.all(get "#{resource_path}/#{id}/deals")
    end

    class << self

      def find_or_create(params)
        find_by_name(params[:name]).first || create(params)
      end

    end
  end
end
