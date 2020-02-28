module Pipedrive
  class Pipeline < Base
    def stages
      Stage.all(nil,  { :pipeline_id => self.id })
    end

    def statistics(id, start_date, end_date)
      res = get("#{resource_path}/#{id}/movement_statistics",
                :query => {:start_date => start_date, :end_date => end_date})
      res.ok? ? new(res) : bad_response(res,{:id=>id,:start_date=>start_date,:end_date=>end_date})
    end

    def deals(stage_id = nil)
      Pipedrive::Deal.all(get "#{resource_path}/#{id}/deals", :query => stage_id.present? ? {:stage_id => stage_id} : {} )
    end

    class << self

      def find_or_create_by_name(name, opts={})
        find_by_name(name) || create(opts.merge(:name => name))
      end

    end
  end
end
