module CommitAndVersion
  extend ActiveSupport::Concern

  included do
    before_create :set_last_published_commit
  end

  protected

  def set_last_published_commit
    return unless self.respond_to? :last_published_commit_hash # product?
    last_commit = self.last_published.first.try :commit_hash
    if last_commit && self.project.repo.commit(last_commit).present? # commit(nil) is not nil!
      self.last_published_commit_hash = last_commit
    end
  end
end
