class Redis
  def self.connect!
    url  = ENV["REDIS_URL"] || "redis://localhost:6379/#{::Rails.env.test? ? 2 : 0}"
    opts = { url: url }

    opts[:logger] = ::Rails.logger if ::Rails.application.config.log_redis

    Redis.current = Redis.new(opts)
  end
end

Redis.connect!
Redis::Semaphore.new(:job_shift_lock).delete!