class Redis
  def self.connect!
    puts ENV["REDIS_URL"]
    puts ENV["REDIS_URL"].presence
    url  = ENV["REDIS_URL"].presence || "redis://localhost:6379/#{::Rails.env.test? ? 1 : 0}"
    opts = { url: url }

    opts[:logger] = ::Rails.logger if ::Rails.application.config.log_redis

    Redis.current = Redis.new(opts)
  end
end

Redis.connect!
