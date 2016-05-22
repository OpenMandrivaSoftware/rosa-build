module BuildLists
  class BuildCancelingDestroyJob
    @queue = :low

    def self.perform
      scope = BuildList.for_status(BuildList::BUILD_CANCELING).for_notified_date_period(nil, 1.hours.ago)

      scope.find_each(batch_size: 50) do |bl|
        bl.destroy
      end
    end
  end
end