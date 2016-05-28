module BuildLists
  class CreateContainerJob < BaseActiveRecordJob
    include Sidekiq::Worker
    sidekiq_options :queue => :middle

    def perform_with_ar_connection(build_list_id)
      build_list  = BuildList.find(build_list_id)
      container   = AbfWorkerService::Container.new(build_list)
      container.create!
    end

  end
end