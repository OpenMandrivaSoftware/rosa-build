require 'base64'

module Project::GithubApi
  extend ActiveSupport::Concern

  def github_data
      Github.repos.get user: github_get_organization, repo: name rescue nil
  end

  def github_branches
      Github.repos.branches user: github_get_organization, repo: name rescue nil
  end

  def github_tags
      Github.repos.tags user: github_get_organization, repo: name rescue nil
  end

  def find_blob_and_raw_of_spec_file(project_version)

  end

  def update_file(path, data, options = {})
    
  end
  
  def github_get_organization
    return github_organization if github_organization.presence
    APP_CONFIG['github_organization']
  end
end