class CleanRpmBuildNodeJob
  include Sidekiq::Worker

  def perform
    RpmBuildNode.all.each do |n|
      n.delete unless n.user_id
    end
  end

end
