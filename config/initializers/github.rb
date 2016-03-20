#configuration of Github api gem

Github.configure do |c|
  c.basic_auth = ENV["GITHUB_LOGIN"] + ":" + ENV["GITHUB_PASSWORD"]
  c.auto_pagination = true
  c.stack = Proc.new do |builder|
    builder.use Faraday::HttpCache, store: Rails.cache, logger: Rails.logger
  end
end

#for updating repo contents
Github_blobs_api = Github::Client::Repos::Contents.new(basic_auth: ENV['GITHUB_REPO_BOT_LOGIN'] + ":" + ENV['GITHUB_REPO_BOT_PASSWORD'])
