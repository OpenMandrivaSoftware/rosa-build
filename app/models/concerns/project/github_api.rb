module Project::GithubApi
  extend ActiveSupport::Concern

  def github_data
      Github.repos.get user: org, repo: name rescue nil
  end

  def github_branches
      Github.repos.branches user: org, repo: name rescue nil
  end

  def github_tags
      Github.repos.tags user: org, repo: name rescue nil
  end

  def github_get_commit(hash)
    Github.repos.commits.list user: org, repo: name, sha: hash rescue nil
  end

  private
  
  def org
    github_organization || APP_CONFIG["github_organization"]
  end
end