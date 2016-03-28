#configuration of Github api gem

Github_blobs_api = Octokit::Client.new(login: ENV['GITHUB_REPO_BOT_LOGIN'], password: ENV['GITHUB_REPO_BOT_PASSWORD'])

Octokit.configure do |c|
  c.login = ENV["GITHUB_LOGIN"]
  c.password = ENV["GITHUB_PASSWORD"]
end
Octokit.middleware = Faraday::RackBuilder.new do |builder|
  store = ActiveSupport::Cache.lookup_store(:redis_store, ENV['REDIS_URL'].to_s + '/1')
  builder.use Faraday::HttpCache, store: store, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end