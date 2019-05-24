module BuildLists
  class ClearStaleBuilders < BaseActiveRecordJob
    include Sidekiq::Worker
    sidekiq_options :queue => :low

    def perform_with_ar_connection
      BuildList.where(["updated_at < ?", 900.seconds.ago]).where(status: BuildList::BUILD_PENDING).where.not(builder: nil).update_all(builder_id: nil)
    end
  end
end
