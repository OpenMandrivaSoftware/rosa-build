require 'base64'

module Project::GithubApi
  extend ActiveSupport::Concern

  def github_data
      Octokit.repo github_get_organization + '/' + name rescue {}
  end

  def github_branches
      Octokit.branches github_get_organization + '/' + name rescue []
  end

  def github_tags
      Octokit.tags github_get_organization + '/' + name rescue []
  end

  def github_last_commit(branch = nil)
    if branch.present?
      Octokit.commits github_get_organization + '/' + name, sha: branch, per_page: 1 rescue []
    else
      Octokit.commits github_get_organization + '/' + name, per_page: 1 rescue []
    end
  end

  def github_get_organization
    return github_organization if github_organization.presence
    APP_CONFIG['github_organization']
  end
end