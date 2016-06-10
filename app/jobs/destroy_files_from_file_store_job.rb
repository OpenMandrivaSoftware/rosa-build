class DestroyFilesFromFileStoreJob
  include Sidekiq::Worker

  sidekiq_options :queue => :low

  def perform(sha1)
    file = FileStoreService::File.new
    sha1.each do |hash|
      file.sha1 = hash
      file.destroy
    end
  end
end