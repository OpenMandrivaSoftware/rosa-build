module CommitAndVersion
  extend ActiveSupport::Concern

  included do
    before_validation :set_version
    before_create :set_last_published_commit
  end

  protected

  def set_version
    if project_version.blank? && commit_hash.present?
      self.project_version = commit_hash
    end
  end

  def set_last_published_commit
    return unless self.respond_to? :last_published_commit_hash # product?
    last_commit = self.last_published.first.try :commit_hash
    if last_commit # commit(nil) is not nil!
      self.last_published_commit_hash = last_commit
    end
  end
end
