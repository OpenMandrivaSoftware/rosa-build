module FileStoreClean
  extend ActiveSupport::Concern

  def destroy
    DestroyFilesFromFileStoreJob.perform_async(sha1_of_file_store_files) if Rails.env.production?
    super
  end

  def sha1_of_file_store_files
    raise NotImplementedError, "You should implement this method"
  end

end
