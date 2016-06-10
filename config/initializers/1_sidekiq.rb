require 'sidekiq/scheduler'

Kiqit.config.enabled = true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML
      .load_file(File.expand_path('../../../config/schedule.yml', __FILE__))
    Sidekiq::Scheduler.reload_schedule!
  end
end

