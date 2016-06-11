class CleanRpmBuildNodeJob
  include Sidekiq::Worker

  sidekiq_options :queue => :low

  def perform
    RpmBuildNode.all.each do |n|
      n.delete unless n.user_id
    end
  end

end
