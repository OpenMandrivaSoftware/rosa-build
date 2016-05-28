class DestroyProjectFromRepositoryJob < BaseActiveRecordJob
  include Sidekiq::Worker
  sidekiq_options :queue => :low

  def perform_with_ar_connection(project_id, repository_id)
    project = Project.find(project_id)
    repository = Repository.find(repository_id)
    service = AbfWorkerService::Repository.new(repository)
    service.destroy_project!(project)
  end

end
