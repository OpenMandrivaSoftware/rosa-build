class AbfWorkerStatusPresenter

  def initialize
  end

  def projects_status
    Rails.cache.fetch([AbfWorkerStatusPresenter, :projects_status], expires_in: 30.seconds) do
      result = {rpm: {}}
      nodes = RpmBuildNode.total_statistics
      result[:rpm][:workers]        = nodes[:systems]
      result[:rpm][:build_tasks]    = nodes[:busy]
      result[:rpm][:other_workers]  = nodes[:others]

      normal_pending = BuildList.for_status(BuildList::BUILD_PENDING).where(mass_build_id: nil).count
      mass_build_pending = BuildList.for_status(BuildList::BUILD_PENDING).where.not(mass_build_id: nil).count

      result[:rpm][:pending] = normal_pending
      result[:rpm][:mass_build_pending] = mass_build_pending

      result
    end
  end

end
