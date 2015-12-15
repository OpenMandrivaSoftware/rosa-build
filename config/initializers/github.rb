#configuration of Github api gem

Github.configure do |c|
  puts ENV["GITHUB_LOGIN"]
  c.basic_auth = ENV["GITHUB_LOGIN"] + ":" + ENV["GITHUB_PASSWORD"]
  c.auto_pagination = true
  c.stack do |builder|
    builder.use Faraday::HttpCache, store: Rails.cache
  end
end
