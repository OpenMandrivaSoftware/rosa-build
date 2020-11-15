#configuration of Github api gem

Github_blobs_api = Octokit::Client.new(access_token: ENV["GITHUB_REPO_BOT_ACCESS_TOKEN"])

Octokit.configure do |c|
  c.access_token = ENV["GITHUB_ACCESS_TOKEN"]
end
Octokit.middleware = Faraday::RackBuilder.new do |builder|
  store = ActiveSupport::Cache.lookup_store(:redis_store, ENV['REDIS_URL'].to_s + '/1')
  builder.use Faraday::HttpCache, store: store, shared_cache: false, serializer: Marshal
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
