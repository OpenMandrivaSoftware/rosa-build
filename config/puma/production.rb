base_path  = "/app/rosa-build"
bind 'unix:///app/rosa-build/rosa_build.sock'

environment ENV['RAILS_ENV'] || 'production'
threads *(ENV['PUMA_THREADS'] || '12,12').split(',')
workers ENV['PUMA_WORKERS'] || 5


preload_app!

on_worker_boot do
  if defined?(ActiveRecord::Base)
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished

      config = Rails.application.config.database_configuration[Rails.env]
      # config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
      # config['pool']              = ENV['DB_POOL']      || 3

      ActiveRecord::Base.establish_connection(config)

      Rails.logger.info "Connected to PG. Connection pool size #{config['pool']}, reaping frequency #{config['reaping_frequency']}"
    end
    # QC::Conn.connect
    Rails.logger.info('Connected to PG')
  end

  Redis.connect!
  Rails.logger.info('Connected to Redis')
end
