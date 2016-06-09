module BuildLists
  class ClearBuilderOnStaleBuildListsJob < BaseActiveRecordJob
    include Sidekiq::Worker
    sidekiq_options :queue => :low

    def perform_with_ar_connection
      BuildList.transaction do
        BuildList.where(["updated_at < ?", 120.seconds.ago]).where(status: BuildList::BUILD_PENDING).where.not(builder: nil).find_each(batch_size: 50) do |bl|
          bl.update_column(builder_id: nil)
        end
      end
    end
  end
end