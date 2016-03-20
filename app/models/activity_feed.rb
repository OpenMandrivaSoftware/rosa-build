class ActivityFeed < ActiveRecord::Base

  BUILD   = %w(build_list_notification)

  belongs_to :user
  belongs_to :creator, class_name: 'User'
  serialize  :data

  default_scope { order created_at: :desc }
  scope :outdated,        -> { offset(1000) }
  scope :by_project_name, ->(name)  { where(project_name: name)   if name.present?  }
  scope :by_owner_uname,  ->(owner) { where(project_owner: owner) if owner.present? }

  self.per_page = 20

  def partial
    "home/partials/#{self.kind}"
  end
end
