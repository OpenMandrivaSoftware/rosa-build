class UpdateStatisticsJob < BaseActiveRecordJob
  include Sidekiq::Worker
  sidekiq_options :queue => :middle

  def perform_with_ar_connection(args = {})
    defaults = {'activity_at' => nil, 
                'user_id' => nil, 
                'project_id' => nil, 
                'key' => nil, 
                'counter' => 1}
    options = defaults.merge(args)
    puts options
    statsd_increment(activity_at: options['activity_at'], user_id: options['user_id'],
                      project_id: options['project_id'], key: options['key'], counter: options['counter'])
  end

  private

  def statsd_increment(activity_at: nil, user_id: nil, project_id: nil, key: nil, counter: 1)
    # Truncates a DateTime to the minute
    activity_at = Time.at(activity_at.to_i).utc.change(min: 0)
    user        = User.find user_id
    project     = Project.find project_id
    Statistic.create(
      user_id:                  user_id,
      email:                    user.email,
      project_id:               project_id,
      project_name_with_owner:  project.name_with_owner,
      key:                      key,
      activity_at:              activity_at
    )
  rescue ActiveRecord::RecordNotUnique
    # Do nothing, see: ensure
  ensure
    Statistic.where(
      user_id:      user_id,
      project_id:   project_id,
      key:          key,
      activity_at:  activity_at
    ).update_all(['counter = counter + ?', counter]) if user_id.present? && project_id.present?
  end

end