module EmptyMetadata
  extend ActiveSupport::Concern

  included do
    after_commit :create_empty_metadata, on: :create
  end

  def create_empty_metadata
    return if is_a?(Platform) && ( personal? || hidden? )
    CreateEmptyMetadataJob.perform_async(self.class.name, id)
  end

end
