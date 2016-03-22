module BuildLists
  class ClearBuilderOnStaleBuildListsJob
    @queue = :low

    def self.perform
      BuildList.where(["updated_at < ?", 120.seconds.ago]).where(status: BuildList::BUILD_PENDING).find_each(batch_size: 50) do |bl|
        bl.builder = nil
        bl.save
      end
    end
  end
end