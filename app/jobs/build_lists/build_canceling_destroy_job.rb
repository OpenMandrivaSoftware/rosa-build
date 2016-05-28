module BuildLists
  class BuildCancelingDestroyJob < BaseActiveRecordJob
    include Sidekiq::Worker
    sidekiq_options :queue => :low

    def perform_with_ar_connection
      scope = BuildList.for_status(BuildList::BUILD_CANCELING).for_notified_date_period(nil, 1.hours.ago)

      scope.find_each(batch_size: 50) do |bl|
        bl.destroy
      end
    end
  end
end